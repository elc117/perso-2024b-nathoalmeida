# Produção Individual Personalizada

## 1. Identificação

**Autora:** Nathália de Almeida Zófoli.

**Curso:** Sistemas de Informação.

## 2. Objetivo

​	Minha proposta de trabalho consiste em desenvolver um jogo simples, utilizando *Web Service* em Haskell, em que o jogador deve adivinhar o ano em que alguma mulher venceu o Prêmio Turing.  Se o jogador inserir um ano incorreto, a aplicação deverá fornecer uma dica aleatória. A premiação é considerada o Nobel da computação, e os vencedores são reconhecidos por suas contribuições duradouras e fundamentais nessa área.

​	A escolha do tema e método de desenvolvimento foi feita considerando o meu desejo de pesquisar e conhecer um pouco sobre a contribuição de mulheres para a computação, além de compreender um pouco sobre desenvolvimento *backend* para serviços *web*.

## 3. Desenvolvimento

​	A execução do trabalho foi realizada em quatro etapas principais: escrita de funções básicas, testes do serviço web com Scotty, construção das mensagens de retorno e, por fim, a adição de uma dica aleatória no caso do jogador inserir uma resposta errada. Para tanto, foram realizadas consultas nos exemplos fornecidos no material da disciplina, na documentação da linguagem Haskell, no *Stack Overflow* e, nos momentos de desespero, no ChatGPT (ajudou uma vez e atrapalhou 10 vezes).

### 3.1. Funções básicas

​	Foram mapeadas algumas funções que seriam fundamentais para a execução do programa: validação do ano inserido pelo jogador, seleção do nome e do gênero de acordo com o ano inserido, validação do gênero de uma tupla, etc.

​	Abaixo, listo algumas funções concebidas na fase inicial de construção do programa e que foram testadas com o GHCi: 

```haskell
-- verifica se o ano inserido está dentro do período de existência do Prêmio Turing
yearCheck :: Int -> Bool
yearCheck year = year >= 1966 && year <= 2023
        
-- retorna o gênero do vencedor do prêmio Turing no ano selecionado
selectGenderByYear :: [(String, Int, String)] -> Int -> String
selectGenderByYear list year = head [ z | (x, y, z) <- list, y == year]

-- retorna o nome do vencedor do prêmio Turing no ano selecionado
selectNameByYear :: [(String, Int, String)] -> Int -> String
selectNameByYear list year = head [ x | (x, y, z) <- list, y == year]

-- verifica se uma String contém a primeira letra 'F', indicando o gênero do vencedor
femaleCheck :: String -> Bool
femaleCheck gender = head gender == 'F'

-- verifica o gênero do vencedor do prêmio Turing no ano selecionado 
isFemale :: [(String, Int, String)] -> Int -> Bool
isFemale list year = femaleCheck $ selectGenderByYear list year
```

​	O uso de list comprehension foi primordial para que o código funcionasse conforme o esperado, pois os vencedores do prêmio foram armazenados em uma lista de tuplas, cada tupla contendo o(s) nome(s) do(s) vencedor(es) de cada ano, seu gênero e o ano da premiação.

​	Algumas outras funções foram acrescentadas ao longo do desenvolvimento do programa, conforme foi identificada a necessidade.

### 3.2. Serviço web com Scotty

​	Em um segundo momento, principalmente devido ao desconhecimento da ferramenta, foram realizados diversos testes do serviço web, principalmente para compreender seu funcionamento, sua interação com as funções básicas e suas incompatibilidades. Devido a dificuldades em configurar o ambiente de desenvolvimento na máquina local, e para poupar tempo, foi utilizado o *Codespaces*, em um dos repositórios previamente criados para a realização de outras atividades da disciplina.

​	Essa foi, portanto, a etapa mais demorada, pois demandou inúmeras versões, tentativas de compilação e, evidentemente, erros e mais erros. A versão final executável desse estágio de desenvolvimento consistiu em uma simples verificação se o ano inserido estava dentro dos limites estabelecidos, aplicando a função yearCheck.

​	A principal dificuldade se deu em razão de um erro simples, mas fatal (como tudo em programação), que comprometeu a leitura do ano inserido na URL da aplicação: a ausência de um cabeçalho.

```haskell
-- duas palavras que teriam me poupado de umas 200 mensagens de erro 
{-# LANGUAGE OverloadedStrings #-}
```

### 3.3. Construção de mensagens de retorno

​	Com o serviço web retornando nosso teste de verificação de ano, o próximo estágio foi, essencialmente, a implementação de novas funções, que retornassem a mensagem de acerto ou de erro. Embora relativamente simples, as funções apresentaram inúmeros erros, e cada tentativa de consertá-los geravam um número de erros ainda maior.

​	Novamente, tratou-se de dois problemas elementares (foi aqui que o chatGPT atrapalhou muito, pois não conseguiu identificar os problemas e sugeriu soluções mirabolantes que só poluíram o código, sem resolver nada):

- Algumas funções básicas, como inicialmente implementadas, retornavam uma lista de valores. Pela construção da lista, eu sabia que a função retornaria apenas um valor, mas a linguagem, não (e, de fato, se eu acrescentasse equivocadamente um nome ou ano duas vezes na lista, ela retornaria uma lista com dois valores). O erro foi corrigido acrescentando a função *head* nas funções¹;

- Erros de indentação na utilização de *if/then/else*. 

  

  As seguintes funções foram acrescentadas para retornar a mensagem, em caso de erro ou de acerto:

  ```haskell
  rightResponse :: [(String, Int, String)] -> Int -> String
  rightResponse list givenYear = first ++ name ++ winner ++ year
  			where	first = "Você está certo! "
            		  	name = selectNameByYear list givenYear
           		 	winner = " venceu o Prêmio Turing em "
            			year = show givenYear
  
  wrongResponse :: [(String, Int, String)] -> Int -> String
  wrongResponse list givenYear = first ++ name ++ winner ++ year
              where   first = "Você errou! "
                      name = selectNameByYear list givenYear
                      winner = "foi quem venceu o Prêmio Turing em "
                      year = show givenYear
   
  -- em uma versão posterior do código, a função answerToJSONFormat foi eliminada, 
  -- pois não era necessária para executar o programa
  getResponseMessage list givenYear = if not $ yearCheck givenYear then pack (answerToJSONFormat "Insira um ano entre 1966 e 2023")
      else if isFemale turingWinners givenYear then pack (answerToJSONFormat (rightResponse turingWinners givenYear))
      else pack (answerToJSONFormat (wrongResponse turingWinners givenYear))
  ```

  

### 3.4. Acréscimo da dica em caso de erro do jogador

​	Para a função que sorteia uma dica aleatória, foi usado, como modelo, o exemplo fornecido no material da disciplina ("Random Advice"). Assim, ela ficou nesse formato:

```haskell
getRandomTip :: IO String
getRandomTip = do
    index <- randomRIO (0, length turingTips - 1)
    return $ turingTips !! index
```

​	Contudo, ficou impossível de concatenar o retorno dessa função com a *String* que informava o jogador que sua resposta estava incorreta. Após inúmeras tentativas de conversão de tipos, deparei-me com uma excelente resposta no *Stack Overflow* que foi uma verdadeira aula de Haskell e de programação funcional.

​	Como estamos tratando de programação funcional, espera-se que as funções não tenham efeitos colaterais (chamadas funções puras). Caso ocorram efeitos colaterais em uma função, ela não poderá ser utilizada junto a uma função pura, sendo impossível "convertê-la" para ser concatenada com o resultado de uma função pura, pois isso fere os princípios da linguagem funcional. Em Haskell, funções puras podem ser usadas em qualquer lugar do código; funções "impuras" somente podem ser utilizadas dentro de outras funções impuras. Como uma frase que o autor da resposta utilizou e que considero muito pertinente: *"Once you go IO you can never go back"*.

​	Por sorte, foram sugeridas soluções para o problema, basicamente transformando nossa função pura em uma função impura. Após várias tentativas de "sujar" minha função, foi possível chegar a um resultado compatível para o funcionamento correto da aplicação:

```haskell
rightResponse :: [(String, Int, String)] -> Int -> String
rightResponse list givenYear = first ++ name ++ winner ++ year
    where first = "Você está certo! "
          name = selectNameByYear list givenYear
          winner = if twoWinners $ selectNameByYear list givenYear then " venceram o Prêmio Turing em " else " venceu o Prêmio Turing em "
          year = show givenYear ++ "."
          
wrongResponse :: [(String, Int, String)] -> Int -> IO String
wrongResponse list givenYear = do
    randomTip <- getRandomTip
    let first = "Você errou! "
        name = selectNameByYear list givenYear
        winner = if twoWinners $ selectNameByYear list givenYear then " venceram o Prêmio Turing em " else " venceu o Prêmio Turing em "
        year = show givenYear ++ ". /// "
        dica = " Dica: " ++ randomTip
    return (first ++ name ++ winner ++ year ++ dica)

getResponseMessage :: [(String, Int, String)] -> Int -> IO String
getResponseMessage list givenYear = 
    if not (yearCheck givenYear) 
        then return $ "Insira um ano entre 1966 e 2023"
    else if isFemale turingWinners givenYear 
        then return $ rightResponse turingWinners givenYear
    else wrongResponse turingWinners givenYear
```

​	Note que a função *rightResponse* permaneceu uma função pura, pois funções puras podem ser utilizadas dentro de funções impuras; o contrário não poderia ocorrer.



## 4. Resultados e conclusão

​	Abaixo, uma demonstração do programa em funcionamento:

![](/home/nathizofoli/Downloads/Gravação de tela de 27-10-2024 20_31_20.gif)

​	Embora seja uma aplicação simples, ela cumpriu com seu objetivo, contribuindo para a construção de conhecimentos em *Web Services* com Haskell, além de divulgar uma fração do trabalho desenvolvido por mulheres na computação. 

​	Havia sido proposta a utilização de persistência de dados, cadastrando um usuário e criando um *leaderboard*. Contudo, não houve tempo hábil para a implementação dessa funcionalidade. Como sugestões de melhoria da aplicação, seria interessante, além do acréscimo do *leaderboard*, o desenvolvimento *frontend*, tornando a aplicação atrativa e mais interativa para o usuário.	



## 5. Referências

- Material da disciplina (https://github.com/AndreaInfUFSM/elc117-2024b);
- *Stack Overflow* (https://stackoverflow.com/questions/11229854/how-can-i-parse-the-io-string-in-haskell);
- ChatGPT;
- Documentações da linguagem Haskell (https://zvon.org/other/haskell/Outputprelude/any_f.html); (https://hackage.haskell.org/package/base-4.20.0.1/docs/Prelude.html#v:head); (https://hackage.haskell.org/package/base-4.20.0.1/docs/Prelude.html#g:26).
