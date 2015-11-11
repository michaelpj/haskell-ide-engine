{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
module Haskell.Ide.Engine.PluginUtils
  (
    getParams
  , mapEithers
  ) where

import           Data.Aeson
import           Data.List
import           Haskell.Ide.Engine.PluginDescriptor
import qualified Data.Map as Map
import           Prelude hiding (log)

-- ---------------------------------------------------------------------

-- TODO: should this be in the haskell-ide-plugins-api

-- |If all the listed params are present in the request resturn their values,
-- else return an error message.
getParams :: Rec MyParamId ts -> IdeRequest -> Either IdeResponse (Rec MyParamVal ts)
getParams params req = go params
  where
    go :: Rec MyParamId ts -> Either IdeResponse (Rec MyParamVal ts)
    go RNil = Right RNil
    go (x:&xs) = case go xs of
                    Left err -> Left err
                    Right ys -> case checkOne x of
                                  Left err -> Left err
                                  Right y -> Right (y:&ys)
    checkOne :: MyParamId t -> Either IdeResponse (MyParamVal t)
    checkOne (IdText param) = case Map.lookup param (ideParams req) of
      Just (ParamText v)  -> Right (MyParamText v)
      _ -> Left $ IdeResponseFail (toJSON $ "need `" ++ show param ++ "` parameter")
    checkOne (IdFile param) = case Map.lookup param (ideParams req) of
      Just (ParamFile v)  -> Right (MyParamFile v)
      _ -> Left $ IdeResponseFail (toJSON $ "need `" ++ show param ++ "` parameter")
    checkOne (IdPos param) = case Map.lookup param (ideParams req) of
      Just (ParamPos v)  -> Right (MyParamPos v)
      _ -> Left $ IdeResponseFail (toJSON $ "need `" ++ show param ++ "` parameter")



-- ---------------------------------------------------------------------
-- courtesy of http://stackoverflow.com/questions/19891061/mapeithers-function-in-haskell
mapEithers :: (a -> Either b c) -> [a] -> Either b [c]
mapEithers f (x:xs) = case mapEithers f xs of
                        Left err -> Left err
                        Right ys -> case f x of
                                      Left err -> Left err
                                      Right y -> Right (y:ys)
mapEithers _ _ = Right []
