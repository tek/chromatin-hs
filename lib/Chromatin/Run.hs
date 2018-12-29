module Chromatin.Run(
  runRplugin,
  RunResult(..),
) where

import Data.List.Split (linesBy)
import Data.MessagePack (Object)
import UnliftIO.Exception (catch)
import Neovim (NeovimException, toObject, fromObject', vim_call_function')
import qualified Neovim as NeovimException (NeovimException(ErrorMessage, ErrorResult))
import qualified Data.Map as Map (fromList)
import Chromatin.Data.Rplugin (Rplugin(Rplugin))
import Chromatin.Data.RpluginName (RpluginName(RpluginName))
import Chromatin.Data.ActiveRplugin (ActiveRplugin(ActiveRplugin))
import Chromatin.Data.RpluginSource (RpluginSource(Stack))
import Chromatin.Data.Chromatin (Chromatin)

data RunResult =
  Success ActiveRplugin
  |
  Failure [String]
  deriving (Show, Eq)

jobstartFailure :: NeovimException -> Either String a
jobstartFailure (NeovimException.ErrorMessage doc) = Left (show doc)
jobstartFailure (NeovimException.ErrorResult obj) = Left (show obj)

unsafeJobstart :: [Object] -> Chromatin Int
unsafeJobstart args = do
  result <- vim_call_function' "jobstart" args
  fromObject' result

jobstart :: [Object] -> Chromatin (Either String Int)
jobstart args =
  catch (Right <$> unsafeJobstart args) (return . jobstartFailure)

runRpluginStack :: RpluginName -> FilePath -> Chromatin (Either String Int)
runRpluginStack (RpluginName name) path = do
  let opts = Map.fromList [("cwd", toObject path), ("rpc", toObject True)]
  jobstart [toObject $ "stack exec " ++ name, toObject opts]

runRplugin' :: RpluginName -> RpluginSource -> Chromatin (Either String Int)
runRplugin' name (Stack path) = runRpluginStack name path
runRplugin' _ _ = return (Left "NI")

runRplugin :: Rplugin -> Chromatin RunResult
runRplugin rplugin@(Rplugin name source) = do
  result <- runRplugin' name source
  return $ case result of
    Right channelId -> Success (ActiveRplugin channelId rplugin)
    Left err -> Failure (linesBy (=='\n') err)