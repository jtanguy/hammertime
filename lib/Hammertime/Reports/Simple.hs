{-# LANGUAGE OverloadedStrings #-}

module Hammertime.Reports.Simple (
    report
) where

import Data.Char (isDigit)
import Data.Foldable (foldMap)
import Data.Function (on)
import Data.List (groupBy, sortBy)
import Data.Maybe (mapMaybe)
import Data.Monoid (mappend)
import qualified Data.Text as T
import Data.Time.Clock (NominalDiffTime)

import Hammertime.Core (getTotalTime)
import Hammertime.Types

report :: ReportGenerator
report spans =
    let pairs = groupByProject spans
        sorted = sortBy (compare `on` fst) pairs
        projects = foldMap reportProject sorted
    in header `mappend` projects

header :: Report
header = "Hammertime report \n\n"

readableTime :: NominalDiffTime -> T.Text
readableTime d =
    let tsecs = (read . takeWhile isDigit . show $ d :: Int)
        (hours, msecs) = divMod tsecs (3600)
        (mins, secs) = divMod msecs (60)
    in T.pack $ show hours ++ " hours " ++ show mins ++ " mins " ++ show secs ++ "s"

reportProject :: (Project, [Span]) -> Report
reportProject (p, spans) =
    let pairs = groupByActivity spans
        sorted = sortBy (compare `on` fst) pairs
        activities = foldMap reportActivity sorted
        totalTime = getTotalTime spans
        displayedTime = readableTime totalTime
        firstLine = p `mappend` ": " `mappend`
                    displayedTime `mappend` "\n"
    in firstLine `mappend` activities `mappend` "\n"

reportActivity :: (Name, [Span]) -> Report
reportActivity (n, spans) =
    let totalTime = getTotalTime spans
        displayedTime = readableTime totalTime
        tab = "  "
    in tab `mappend`
       n `mappend` ": " `mappend`
       displayedTime `mappend` "\n"

groupByProject :: [Span] -> [(Project, [Span])]
groupByProject = makeAssocList (project . activity)

groupByActivity :: [Span] -> [(Name, [Span])]
groupByActivity = makeAssocList (name . activity)

makeAssocList :: (Eq a, Ord a) => (Span -> a) -> [Span] -> [(a, [Span])]
makeAssocList prop = mapMaybe makePair . groupBy ((==) `on` prop) . sortBy (compare `on` prop)
    where
        makePair spans@(s:_) = Just (prop s,spans)
        makePair _ = Nothing
