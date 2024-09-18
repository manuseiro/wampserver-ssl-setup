@echo off
:: Limpa a tela
cls

:: Habilita a expansão atrasada de variáveis
setlocal enabledelayedexpansion

:: Define variáveis comuns de instalação
set "diretorios_instalacao=C:\wamp64 C:\wamp D:\wamp64 D:\wamp"
set "diretorio_wamp="
set "diretorio_apache="
set "logfile=wamp_ssl_setup.log"

:: Corrige a exibição de caracteres especiais utf-8 no prompt de comando
chcp 65001 > nul

:: Verifica se o script está sendo executado como administrador
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo Por favor, execute este script como administrador.
    echo Fechando em 5 segundos...
    timeout /t 5 >nul
    exit /b
)

:: Verifica se o OpenSSL está instalado
where openssl >nul 2>&1
if %errorlevel% neq 0 (
    echo OpenSSL não foi encontrado no PATH. Por favor, instale ou adicione ao PATH.
    pause
    exit /b
)

:executarScript

:: Verifica diretórios de instalação do WAMP
call :verificar_diretorios
if not defined diretorio_wamp (
    echo Não foi encontrado o diretório da instalação do WAMP.
    echo Exemplo: "C:\wamp64"
    set /p "diretorio_wamp=Informe o diretório de instalação do WAMP: "
    if not exist "!diretorio_wamp!" (
        echo O diretório "!diretorio_wamp!" não é válido.
        pause
        cls
        goto :executarScript
    )
)
echo Diretório da instalação do WAMP encontrado: %diretorio_wamp%

:: Busca o diretório de instalação do Apache
call :verificar_apache
if not defined diretorio_apache (
    echo Não foi encontrado o diretório da instalação do Apache.
    echo Verifique se a instalação WampServer está correta e tente novamente.
    exit /b
) else (
    echo Diretório da instalação do Apache encontrado: %diretorio_apache%
    call :backup_configs
    call :gerar_certificado
    call :configurar_apache
    call :reiniciar_apache
    echo Certificado instalado com sucesso.
)

:: Abre a página do projeto no navegador
start https://github.com/abmvdigital/wampserver-ssl-setup

exit /b

:verificar_diretorios
for %%d in (%diretorios_instalacao%) do (
    if exist "%%d" (
        set "diretorio_wamp=%%d"
        exit /b
    )
)

:: Se não encontrou, procura no registro do Windows
for /f "tokens=3*" %%a in ('reg query "HKLM\Software\WAMPServer" /v InstallDir 2^>nul') do (
    if exist "%%b" (
        set "diretorio_wamp=%%b"
        exit /b
    )
)
exit /b

:verificar_apache
for /d %%a in ("%diretorio_wamp%\bin\apache\apache*") do (
    set "diretorio_apache=%%~fa"
    exit /b
)
exit /b

:backup_configs
:: Cria backup dos arquivos de configuração
echo Criando backup dos arquivos de configuração...
copy "%diretorio_apache%\conf\httpd.conf" "%diretorio_apache%\conf\httpd.conf.bak"
copy "%diretorio_apache%\conf\extra\httpd-ssl.conf" "%diretorio_apache%\conf\extra\httpd-ssl.conf.bak"
echo Backup concluído. >> %logfile%
exit /b

:gerar_certificado
cd /d "%diretorio_apache%\bin"

:: Solicita ao usuário a senha (opcional)
set /p "senha_certificado=Digite a senha para o certificado (deixe em branco para padrão): "
if "%senha_certificado%"=="" set "senha_certificado=sua_senha"

:: Solicita ao usuário informações do certificado (opcional)
set "default_subj=/C=BR/ST=Minas Gerais/L=Minas Gerais/O=localhost/OU=localhost/CN=localhost"
set /p "informacoes_certificado=Digite as informações do certificado (deixe em branco para padrão): "
if "%informacoes_certificado%"=="" set "informacoes_certificado=%default_subj%"

:: Solicita nome do certificado
set /p "nome_certificado=Digite o nome do certificado (padrão: server): "
if "%nome_certificado%"=="" set "nome_certificado=server"

:: Cria o arquivo de configuração do certificado
(
echo authorityKeyIdentifier=keyid,issuer
echo basicConstraints=CA:FALSE
echo keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
echo subjectAltName = @alt_names
echo [alt_names]
echo DNS.1 = localhost
) > domains.ext

:: Solicita domínios adicionais
set /p "dominios_adicionais=Digite domínios adicionais (separados por espaço, ou deixe em branco): "
if not "%dominios_adicionais%"=="" (
    echo DNS.2 = %dominios_adicionais% >> domains.ext
)

:: Cria a requisição do certificado
openssl req -new -out "%nome_certificado%.csr" -passout pass:%senha_certificado% -subj "%informacoes_certificado%" >> %logfile% 2>&1

:: Gera a chave privada
openssl rsa -in privkey.pem -out "%nome_certificado%.key" -passin pass:%senha_certificado% >> %logfile% 2>&1

:: Gera o certificado
openssl x509 -in "%nome_certificado%.csr" -out "%nome_certificado%.crt" -req -signkey "%nome_certificado%.key" -days 3650 -sha256 -extfile domains.ext >> %logfile% 2>&1

:: Remove arquivos desnecessários
del privkey.pem "%nome_certificado%.csr" domains.ext

:: Move os arquivos para o diretório de configuração do Apache
move /y "%nome_certificado%.crt" "%diretorio_apache%\conf\server.crt"
move /y "%nome_certificado%.key" "%diretorio_apache%\conf\server.key"

exit /b

:configurar_apache
:: Configura o arquivo httpd.conf
set "arquivo_httpd_conf=%diretorio_apache%\conf\httpd.conf"
powershell -Command "(Get-Content '%arquivo_httpd_conf%') -replace '#LoadModule ssl_module modules/mod_ssl.so', 'LoadModule ssl_module modules/mod_ssl.so' | Set-Content '%arquivo_httpd_conf%'"
powershell -Command "(Get-Content '%arquivo_httpd_conf%') -replace '#Include conf/extra/httpd-ssl.conf', 'Include conf/extra/httpd-ssl.conf' | Set-Content '%arquivo_httpd_conf%'"
powershell -Command "(Get-Content '%arquivo_httpd_conf%') -replace '#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so', 'LoadModule socache_shmcb_module modules/mod_socache_shmcb.so' | Set-Content '%arquivo_httpd_conf%'"

:: Configura o arquivo httpd-ssl.conf
set "arquivo_httpd_ssl_conf=%diretorio_apache%\conf\extra\httpd-ssl.conf"
powershell -Command "(Get-Content '%arquivo_httpd_ssl_conf%') -replace 'DocumentRoot.*', 'DocumentRoot \"${INSTALL_DIR}/www\"' | Set-Content '%arquivo_httpd_ssl_conf%'"
powershell -Command "(Get-Content '%arquivo_httpd_ssl_conf%') -replace 'ServerName.*', 'ServerName localhost:443' | Set-Content '%arquivo_httpd_ssl_conf%'"

:: Instala o certificado
set "caminho_certificado=%diretorio_apache%\conf\server.crt"
certutil -addstore -user "Root" "%caminho_certificado%" >> %logfile% 2>&1

exit /b

:reiniciar_apache
:: Reinicia o serviço do Apache
echo Reiniciando o Apache...
net stop wampapache64 >nul 2>&1
net start wampapache64 >nul 2>&1
if %errorlevel% neq 0 (
    echo Falha ao reiniciar o Apache. Verifique as permissões e tente novamente.
    exit /b
)
echo Apache reiniciado com sucesso.
exit /b
