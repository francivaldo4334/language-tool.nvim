# language-tool.nvim
## instalação utilizando o Lazy
```lua
return {
  "francivaldo4334/language-tool.nvim",
  opts = {},
}
```
## Forma de uso
o plugin oferece duas formas de cosultar a api<p>
### primeira forma <p>
utilizando o user_command :LanguageToolCheck
```
:LanguageToolCheck <linguagem> <texto>
```
exemplo:
```
:LanguageToolCheck pt-BR configuracao
```
### segunda forma <p>
utilizado a keymap <leader>lt em modo virtual
em modo virtual do selecione um trecho para enviar para o languagetool fazer uma analize.
esse commando utiliza o parametro defautl_language para obter a linguagem que vai ser analizada
```lua
return {
  "francivaldo4334/language-tool.nvim",
  opts = {
    default_language="pt-BR
  },
}
```
## configurações padrão
```lua
return {
  "francivaldo4334/language-tool.nvim",
  opts = {
  	default_language = "pt-BR",
  	api_type = "restapi",
  	hestapi = "https://api.languagetoolplus.com/",
  	words = {
  		notify_invalid_api_type = "api_type: valor inesperado!",
  		notify_curl_required = "Error: comando 'curl' nao encontrado!",
  		user_command_check_description = "Raliza uma consulta a api language tool",
  		user_command_check_required_args = "Error: comando chedk requer dois argumentos <language> <text>",
  		notify_no_write_cache_text = "Error: nao foi possivel salvar o arquivo de texto",
  		notify_no_write_commandline = "Error: nao foi possivel salvar o arquivo executavel",
  		notify_command_error = "Error: commandline nao encontrado",
  	},
  	commandline = "languagetool_commandline",
  	languagetool_commandline_jar = "",
  	user_commands = {
  		LanguageToolCheck = "LanguageToolCheck",
  	},
  },
}
```
## Opções de api
#### O plugin oferece duas formas de consula a api utilizando a api http podendo ser um servidor local o a api publica disponivel em https://api.languagetoolplus.com/ ou por meio da utilização do cli open source
#### link para o projeto languagetool https://languagetool.org/
## Como configurar uma api http
para definir api http deve definir o parametro api_type como "restapi"
e no parametro hestapi deve definir a rota base da api
```lua
return {
  "francivaldo4334/language-tool.nvim",
  opts = {
    api_type = "restapi",
    hestapi = "http://localhost:8081/"
  },
}
```
por padrão o parametro hestapi é definido como "https://api.languagetoolplus.com/"
## Como configurar o uso de commadline
caso queira utilizar um commadline do languagetool deve definir o parametro api_type como "commandline" e o parametro commandline com o nome do arquivo executavel que fara a consulta ao languagetool
```lua
return {
  "francivaldo4334/language-tool.nvim",
  opts = {
    api_type = "commandline",
    commandline = "seu_commandline_do_languagetool_commondline.sh"
  },
}
```
### Atenção!
em caso queira utilizar o commandline do languagetool com extenção .jar no lugar de passar o parametro commandline deve especificar o parametro languagetool_commandline_jar como o caminho exato do arquivo .jar
isso fara com que a extenção crie automaticamente um .sh como interface para o .jar no diretorio ~/.local/share/nvim/languagetool-commandline.sh
```lua
return {
  "francivaldo4334/language-tool.nvim",
  opts = {
    api_type = "commandline",
    languagetool_commandline_jar = "/opt/LanguageTool-6.6-SNAPSHOT/languagetool-commandline.jar",
  },
}
```
