# WampServer SSL Setup

Um script em lote (batch) para automatizar o processo de configuração de um certificado SSL válido para o WampServer em ambientes Windows.

## Descrição

Este script simplifica significativamente o processo de configuração do SSL para desenvolvimento local ou pequenos ambientes de produção baseados no WampServer. Ele detecta automaticamente o diretório de instalação do WampServer, gera um certificado SSL autoassinado para o servidor local, configura o Apache para usar o certificado SSL gerado e instala o certificado SSL no repositório de Autoridades de Certificação Raiz Confiável do Windows.

## Como Usar

1. Execute o script como administrador.
2. Siga as instruções apresentadas pelo script para fornecer o diretório de instalação do WampServer, se necessário.
3. O script irá gerar o certificado SSL e configurar o Apache automaticamente.
4. Após a conclusão, o certificado SSL estará pronto para uso no servidor local.
 
## 🌟 Apoie o Wampserver SSL Setup!

Use a chave PIX abaixo para fazer sua doação:


![QRCODE PIX](https://raw.githubusercontent.com/abmvdigital/wampserver-ssl-setup/main/QRCODE_PIX.png)

## Licença

Este projeto está licenciado sob a [Licença MIT](LICENSE).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![GitHub issues](https://img.shields.io/github/issues/abmvdigital/wampserver-ssl-setup)](https://github.com/abmvdigital/wampserver-ssl-setup/issues) [![GitHub forks](https://img.shields.io/github/forks/abmvdigital/wampserver-ssl-setup)](https://github.com/abmvdigital/wampserver-ssl-setup/network) [![GitHub stars](https://img.shields.io/github/stars/abmvdigital/wampserver-ssl-setup)](https://github.com/abmvdigital/wampserver-ssl-setup/stargazers) [![GitHub contributors](https://img.shields.io/github/contributors/abmvdigital/wampserver-ssl-setup)](https://github.com/abmvdigital/wampserver-ssl-setup/graphs/contributors)

## Contribuição

Contribuições são bem-vindas! Por favor, leia o [guia de contribuição](CONTRIBUTING.md) para obter mais detalhes sobre como enviar solicitações pull, relatar problemas, etc.
