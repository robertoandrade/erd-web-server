{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Main where

import           Control.Applicative
import           Snap.Core
import           Snap.Util.FileServe
import           Snap.Http.Server
import qualified Data.ByteString.Char8 as BS
import           Control.Monad.IO.Class (MonadIO(..))
import           Control.Monad.Trans.Either
import           Data.Monoid (mempty)
import           Data.Foldable (forM_)

import           Data.ByteString (ByteString)
import           Snap.Util.FileServe
import           Data.Monoid
import           Data.Maybe

import           Data.HashMap.Strict (HashMap)
import qualified Data.HashMap.Strict as H

import           Data.Text (Text)
import qualified Data.Text as DT
import qualified Data.Text.IO as T
import qualified Data.Vector as V
import           Data.Text.Encoding
import qualified Data.ByteString as DBS
import           System.IO
import           Parse
import           ER
import           ErdMain
import qualified Data.ByteString.Lazy          as BL
import qualified Data.ByteString.Lazy.Internal as BLI
import qualified Data.GraphViz.Types.Generalised as G
import qualified Data.Text.Lazy as L
import           Data.Knob
import           Data.GraphViz.Commands
import           System.Random
import           Text.Karver

main :: IO ()
main = quickHttpServe site

-- Routes

site :: Snap ()
site =
    ifTop viewIndex <|>
    route [ ("generate", generate)
          ] <|>
    dir "assets" (serveDirectory "assets") <|>
    dir "generated" (serveDirectory "generated")

viewIndex :: Snap ()
viewIndex = do 
    erCode <- erdText;
    let templateValues = templateHashMap $ DT.pack $ erCode

    liftIO $ putStrLn "(Processing index request)"
    liftIO $ putStrLn $ erCode

    template <- liftIO $ T.readFile "templates/index.karver"

    let html = renderTemplate templateValues template

    writeText html

generate :: Snap ()
generate = do
    erCode <- erdText;
    liftIO $ putStrLn "(Processing generate request)"
    res <- liftIO $ processErCode $ erCode

    case res of Left errorMsg -> writeBS $ BS.pack $ "{ \"error\" : \"" ++ (escape errorMsg) ++ "\" }"
                Right image -> do
                    randomId :: Int <- liftIO $ randomIO
                    let fileName = "generated/diagram_" ++ (show randomId) ++ ".png"
                    liftIO $ BS.writeFile fileName image
                    writeBS $ BS.pack  $ "{ \"image\" : \"" ++ fileName ++ "\" }"
                    return ()
    liftIO $ putStrLn "  Done."

-- Internal functions

templateHashMap :: Text -> HashMap Text Value
templateHashMap erdText = H.fromList $
  [ ("erdText", Literal erdText)
  ]

erdText :: Snap String 
erdText = do
    param <- getParam "erdText"
    lContent <- getRequestBody
    case param of
        Just s -> return $ BS.unpack $ s
        Nothing -> return $ BS.unpack $ toStrictBS lContent

processErCode :: String -> IO (Either String ByteString)
processErCode code = do
    -- the name we pass to loadERFromText does not really matter
    res :: Either String ER <- loadERFromText "generated_image.png" (L.pack code)
    case res of
        Left err -> do return $ Left err
        Right er -> do
            let dotted :: G.DotGraph L.Text = dotER er
            let getData handle = do bytes <- BS.hGetContents handle
                                    return bytes
            let fmt :: GraphvizOutput = Png
            gvizRes :: ByteString <- graphvizWithHandle Dot dotted fmt getData
            return $ Right gvizRes

toStrictBS = BS.concat . BL.toChunks

escape [] = []
escape ('"':s) = "\\\"" ++ escape(s)
escape (c:s) = [c] ++ escape(s)

