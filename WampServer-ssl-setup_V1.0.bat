@echo off

:: Limpa a tela
cls

:: Habilita a expansão atrasada de variáveis
setlocal enabledelayedexpansion 

:: Define variáveis
set "diretorios_instalacao=C:\wamp64 C:\wamp D:\wamp64 D:\wamp"
set "diretorio_wamp="
set "diretorio_apache="

:: Corrige a exibição de caracteres especiais utf-8 no prompt de comando
chcp 65001 > nul

:: Verifica se o script está sendo executado como administrador
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system" && (
    goto :executarScript
) || (
    echo Por favor, execute este script como administrador.
    pause
    exit /b
)

:executarScript

:: Verificação da existência dos possíveis diretórios de instalação do WampServer
for %%d in (%diretorios_instalacao%) do (
    if exist "%%d" (
        set "diretorio_wamp=%%d"
        goto :confirmar_diretorio_wamp
    )
)

:confirmar_diretorio_wamp
if defined diretorio_wamp (
    echo O diretório da instalação do WAMP encontrado é: !diretorio_wamp!
    set /p "confirmacao=Está correto? (S/N): "
    if /I "!confirmacao!" neq "S" (
        set "diretorio_wamp="
        goto :Definir_diretorio_wamp
    )
) else (
    goto :Definir_diretorio_wamp
)

:Definir_diretorio_wamp
if not defined diretorio_wamp (
    echo Não foi encontrado o diretório da instalação do WAMP.
    echo Exemplo: "C:\wamp64"
    set /p "diretorio_wamp=Informe o diretório da instalação do WAMP: "

    :: Verifica se o diretório informado não existe
    if not exist "!diretorio_wamp!" (
        echo O diretório "!diretorio_wamp!" não é válido.
        pause
        cls
        goto :Definir_diretorio_wamp
    )
)
echo Diretório da instalação do WAMP confirmado: %diretorio_wamp%

:: Busca o diretório de instalação do Apache
for /d %%a in ("%diretorio_wamp%\bin\apache\apache*") do (
    set "diretorio_apache=%%~fa"
    goto :verificar_diretorio_apache
)

:verificar_diretorio_apache
if not defined diretorio_apache (
    cls
    echo Não foi encontrado o diretório da instalação do Apache.
    echo Verifique se a instalação WampServer está correta e tente novamente.
    exit /b
) else (
    echo Diretório da instalação do Apache encontrado: %diretorio_apache%

    cd /d "%diretorio_apache%"

    set "OPENSSL_CONF=%diretorio_apache%\conf\openssl.cnf"

    cd /d "%diretorio_apache%\bin"

    :: Solicita as informações do certificado ao usuário
    set /p "cert_country=Informe o código do país (C) [BR]: "
    if "!cert_country!"=="" set "cert_country=BR"
    
    set /p "cert_state=Informe o estado (ST) [Ceara]: "
    if "!cert_state!"=="" set "cert_state=Minas Gerais"
    
    set /p "cert_locality=Informe a localidade (L) [Fortaleza]: "
    if "!cert_locality!"=="" set "cert_locality=Minas Gerais"
    
    set /p "cert_organization=Informe a organização (O) [localhost]: "
    if "!cert_organization!"=="" set "cert_organization=localhost"
    
    set /p "cert_organizational_unit=Informe a unidade organizacional (OU) [localhost]: "
    if "!cert_organizational_unit!"=="" set "cert_organizational_unit=localhost"
    
    set /p "cert_cn=Informe o nome comum (CN) [localhost]: "
    if "!cert_cn!"=="" set "cert_cn=localhost"
    
    set /p "cert_password=Informe a senha da chave privada [sua_senha]: "
    if "!cert_password!"=="" set "cert_password=sua_senha"

    :: Cria o arquivo de configuração do certificado
    echo authorityKeyIdentifier=keyid,issuer > domains.ext
    echo basicConstraints=CA:FALSE >> domains.ext
    echo keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment >> domains.ext
    echo subjectAltName = @alt_names >> domains.ext
    echo [alt_names] >> domains.ext
    echo DNS.1 = localhost >> domains.ext

    :: Cria a requisição do certificado
    openssl req -new -out server.csr -passout pass:%cert_password% -subj "/C=%cert_country%/ST=%cert_state%/L=%cert_locality%/O=%cert_organization%/OU=%cert_organizational_unit%/CN=%cert_cn%"

    :: Gera a chave privada
    openssl rsa -in privkey.pem -out server.key -passin pass:%cert_password%

    :: Gera o certificado usando a requisição do certificado e a chave privada
    openssl x509 -in server.csr -out server.crt -req -signkey server.key -days 3650 -sha256 -extfile domains.ext
    
    :: Deleta arquivos desnecessários
    del privkey.pem
    del server.csr
    del domains.ext

    :: Move os arquivos para o diretório de configuração do Apache
    move /y server.crt %diretorio_apache%\conf\server.crt
    move /y server.key %diretorio_apache%\conf\server.key    
)

:: Bloco de código para configurar o arquivo httpd.conf
set "arquivo_httpd_conf=%diretorio_apache%\conf\httpd.conf"

:: Substitui "#LoadModule ssl_module modules/mod_ssl.so" por "LoadModule ssl_module modules/mod_ssl.so"
powershell -Command "(Get-Content '%arquivo_httpd_conf%') -replace '#LoadModule ssl_module modules/mod_ssl.so', 'LoadModule ssl_module modules/mod_ssl.so' | Set-Content '%arquivo_httpd_conf%'"

:: Substitui "#Include conf/extra/httpd-ssl.conf" por "Include conf/extra/httpd-ssl.conf"
powershell -Command "(Get-Content '%arquivo_httpd_conf%') -replace '#Include conf/extra/httpd-ssl.conf', 'Include conf/extra/httpd-ssl.conf' | Set-Content '%arquivo_httpd_conf%'"

:: Substitui "#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so" por "LoadModule socache_shmcb_module modules/mod_socache_shmcb.so"
powershell -Command "(Get-Content '%arquivo_httpd_conf%') -replace '#LoadModule socache_shmcb_module modules/mod_socache_shmcb.so', 'LoadModule socache_shmcb_module modules/mod_socache_shmcb.so' | Set-Content '%arquivo_httpd_conf%'"

:: Bloco de código para configurar o arquivo httpd-ssl.conf
set "arquivo_httpd_ssl_conf=%diretorio_apache%\conf\extra\httpd-ssl.conf"

:: Substitui a linha "DocumentRoot" por "DocumentRoot "${INSTALL_DIR}/www""
powershell -Command "(Get-Content '%arquivo_httpd_ssl_conf%') -replace 'DocumentRoot.*', 'DocumentRoot "${INSTALL_DIR}/www"' | Set-Content '%arquivo_httpd_ssl_conf%'"

:: Substitui a linha "ServerName" por "ServerName localhost:443"
powershell -Command "(Get-Content '%arquivo_httpd_ssl_conf%') -replace 'ServerName.*', 'ServerName localhost:443' | Set-Content '%arquivo_httpd_ssl_conf%'"

:: Instala o certificado
set "caminho_certificado=%diretorio_apache%\conf\server.crt"
certutil -addstore -user "Root" "%caminho_certificado%"

cls

echo Certificado instalado com sucesso.

pause

:: Abre a página do projeto no navegador
start https://github.com/manuseiro/wampserver-ssl-setup
