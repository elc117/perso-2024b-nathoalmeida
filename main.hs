{-# LANGUAGE OverloadedStrings #-}
import Web.Scotty
import Network.Wai.Middleware.RequestLogger (logStdoutDev)
import System.Random (randomRIO)
import Control.Monad.IO.Class (liftIO)
import Data.Text.Lazy as LT (Text, unpack, pack, fromStrict)
import Text.Printf (printf)

-- Lista com vencedores do Turing Award
turingWinners = [("Alan Perlis", 1966, "M"), ("Maurice Vincent Wilkes", 1967, "M"),("Richard Hamming", 1968, "M"),("Marvin Minsky", 1969, "M"),
    ("James H. Wilkinson", 1970, "M"),("John McCarthy", 1971, "M"),("Edsger Dijkstra", 1972, "M"),("Charles Bachman", 1973, "M"),
    ("Donald Knuth", 1974, "M"),("Allen Newell; Herbert Simon", 1975, "M"),("Michael Rabin; Dana Scott", 1976, "M"),("John Backus", 1977, "M"),
    ("Robert Floyd", 1978, "M"),("Kenneth Iverson", 1979, "M"),("Charles Antony R. Hoare", 1980, "M"), ("Edgar Frank Codd", 1981, "M"),
    ("Stephen Cook", 1982, "M"),("Ken Thompson; Dennis Ritchie", 1983, "M"),("Niklaus Wirth", 1984, "M"),("Richard Karp", 1985, "M"),
    ("John Hopcroft; Robert Tarjan", 1986, "M"),("John Cocke", 1987, "M"),("Ivan Sutherland", 1988, "M"),("William Kahan", 1989, "M"),
    ("Fernando Corbató", 1990, "M"),("Robin Milner", 1991, "M"),("Butler Lampson", 1992, "M"),("Juris Hartmanis; Richard Stearns", 1993, "M"),
    ("Edward Feigenbaum; Raj Reddy", 1994, "M"),("Manuel Blum", 1995, "M"),("Amir Pnueli", 1996, "M"),("Douglas Engelbart", 1997, "M"),
    ("Alan Perlis", 1966, "M"),("Alan Perlis", 1966, "M"),("Alan Perlis", 1966, "M"),("Alan Perlis", 1966, "M"),
    ("James Gray", 1998, "M"),("Fred Brooks", 1999, "M"),("Andrew Chi-Chih Yao", 2000, "M"),("Ole-Johan Dahl; Kristen Nygaard", 2001, "M"),
    ("Ronald Rivest; Adi Shamir; Leonard Adleman", 2002, "M"),("Alan Kay", 2003, "M"),("Vint Cerf; Robert Kahn", 2004, "M"),("Peter Naur", 2005, "M"),
    ("Frances Allen", 2006, "F"),("Edmund Clark; Ernest Allen Emerson; Joseph Sifakis", 2007, "M"),("Barbara Liskov", 2008, "F"),("Charles Thacker", 2009, "M"),
    ("Leslie Valiant", 2010, "M"),("Judea Pearl", 2011, "M"),("Silvio Micali; Shafrira Goldwasser", 2012, "FM"),("Leslie Lamport", 2013, "M"),
    ("Michael Stonebraker", 2014, "M"),("Martin Hellman; Whitfield Diffie", 2015, "M"),("Tim Berners-Lee", 2016, "M"),("David A. Patterson; John LeRoy Hennessy", 2017, "M"),
    ("Yoshua Bengio; Geoffrey Hinton; Yann LeCun", 2018, "M"),("Edwin Catmull; Pat Hanrahan", 2019, "M"),("Alfred Aho; Jeffrey Ullman", 2020, "M"),("Jack Dongarra", 2021, "M"),
    ("Robert Metcalfe", 2022, "M"),("Avi Wigderson", 2023, "M")]

-- Dicas 
turingTips = [ "A primeira mulher a vencer o prêmio Turing faleceu em 2020, aos 88 anos.",
                "Uma das vencedoras foi rejeitada na Pós-Graduação da Universidade de Princeton, pois não aceitavam mulheres na época.",
                "A contribuição na otimização de compiladores na IBM e na computação de alto desempenho renderam a ela o prêmio Turing.",
                "Uma das mulheres divide o prêmio Turing com um colega homem.",
                "Apenas três mulheres venceram o Prêmio Turing até o dia de hoje.",
                "A vencedora mais jovem tem, atualmente, 66 anos.",
                "Uma delas é co-inventora da criptografia probabilística e ferramentas fundamentais para projetos de protocolos criptográficos.",
                "Uma das vencedoras concebeu e implementou a linguagem CLU, que influenciou linguagens como Java, Python e C#."
                ]

getRandomTip :: IO String
getRandomTip = do
    index <- randomRIO (0, length turingTips - 1)
    return $ turingTips !! index

twoWinners :: String -> Bool
twoWinners winner = any (';' ==) winner

yearCheck :: Int -> Bool
yearCheck year = year >= 1966 && year <= 2023
                      
selectGenderByYear :: [(String, Int, String)] -> Int -> String
selectGenderByYear list year = head [ z | (x, y, z) <- list, y == year]

selectNameByYear :: [(String, Int, String)] -> Int -> String
selectNameByYear list year = head [ x | (x, y, z) <- list, y == year]

femaleCheck :: String -> Bool
femaleCheck gender = head gender == 'F'

isFemale :: [(String, Int, String)] -> Int -> Bool
isFemale list year = femaleCheck $ selectGenderByYear list year

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

-- main Scotty
main :: IO ()
main = scotty 3000 $ do
    middleware logStdoutDev  -- Log requests for development

    get "/turingwomen" $ do
        text (pack "Será que você consegue adivinhar o ano em que uma mulher venceu o prêmio Turing? Insira no final da URL /ano")

    -- Rota para verificar se uma mulher venceu o prêmio Turing naquele ano
    get "/turingwomen/:year" $ do
        setHeader "Content-Type" "application/json"
        givenYear <- param "year" :: ActionM Int
        responseMessage <- liftIO $ getResponseMessage turingWinners givenYear
        text (pack responseMessage)


