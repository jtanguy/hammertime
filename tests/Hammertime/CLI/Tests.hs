module Hammertime.CLI.Tests (tests) where

import Test.Tasty
import Test.Tasty.HUnit

import Options.Applicative

import Hammertime.CLI (cliParserInfo, cliParserPrefs, Action(..))
import Hammertime.Types (TimeSpan(..), ReportType(..))

tests :: TestTree
tests = testGroup "Hammertime.CLI.Tests"
    [
        testGroup "Start"
        [
            testCase "start" testStart,
            testCase "start with tags" testStartWithTags,
            testCase "bogus start" testBogusStart

        ],
        testCase "stop" testStop,
        testGroup "Report"
        [
            testCase " default report" testReport,
            testGroup "report with span"
            [
                testCase "month" $ testReportSpan ("month", Month),
                testCase "week" $ testReportSpan ("week", Week),
                testCase "day" $ testReportSpan ("day", Day)
            ],
            testGroup "report with filter"
            [
                testCase "project" testReportFilterProject,
                testCase "activity" testReportFilterActivity,
                testCase "tag" testReportFilterTag
            ],
            testGroup "report with type"
            [
                testCase "simple" $ testReportType ("simple", Simple),
                testCase "total" $ testReportType ("totaltime", TotalTime)
            ]
        ],
        testCase "current" testCurrent
    ]


runCliParser :: [String] -> ParserResult Action
runCliParser = execParserPure cliParserPrefs cliParserInfo


--------------------------------------------------------------------------------
-- Start
--

testStart =
    let result = runCliParser ["start", "project", "activity"]
    in case result of
        Failure (ParserFailure _) -> assertFailure "parse fail: start"
        Success a -> a @=? Start "project" "activity" []
        (CompletionInvoked _) -> assertFailure "Completion invoked"

testStartWithTags =
    let result = runCliParser ["start", "project", "activity", "tag1", "tag2", "tag3"]
    in case result of
        Failure (ParserFailure _) -> assertFailure "parse fail: start with tags"
        Success a -> a @=? Start "project" "activity" ["tag1", "tag2", "tag3"]
        (CompletionInvoked _) -> assertFailure "Completion invoked"

testBogusStart =
    let result = runCliParser ["start"]
    in case result of
        Failure f -> return ()
        Success a -> assertFailure "bogus start accepted"
        (CompletionInvoked _) -> assertFailure "Completion invoked"

--------------------------------------------------------------------------------
-- Stop
--

testStop =
    let result = runCliParser ["stop"]
    in case result of
        Failure (ParserFailure _) -> assertFailure "parse fail: stop"
        Success a -> a @=? Stop
        (CompletionInvoked _) -> assertFailure "Completion invoked"

--------------------------------------------------------------------------------
-- Report
--

testReport =
    let result = runCliParser ["report"]
    in case result of
        Failure (ParserFailure _) -> assertFailure "parse fail: report"
        Success a -> a @=? (Report Day Nothing Nothing Nothing Simple)
        (CompletionInvoked _) -> assertFailure "Completion invoked"

testReportSpan (string, span) =
    let result = runCliParser ["report", string]
    in case result of
        Failure (ParserFailure _) -> assertFailure "parse fail: report"
        Success a -> a @=? (Report span Nothing Nothing Nothing Simple)
        (CompletionInvoked _) -> assertFailure "Completion invoked"

testReportFilterProject =
    let result = runCliParser ["report", "--project", "project"]
    in case result of
        Failure (ParserFailure _) -> assertFailure "parse fail: report"
        Success a -> a @=? (Report Day (Just "project") Nothing Nothing Simple)
        (CompletionInvoked _) -> assertFailure "Completion invoked"

testReportFilterActivity =
    let result = runCliParser ["report", "--activity", "activity"]
    in case result of
        Failure (ParserFailure _) -> assertFailure "parse fail: report"
        Success a -> a @=? (Report Day Nothing (Just "activity") Nothing Simple)
        (CompletionInvoked _) -> assertFailure "Completion invoked"

testReportFilterTag =
    let result = runCliParser ["report", "--tag", "tag"]
    in case result of
        Failure (ParserFailure _) -> assertFailure "parse fail: report"
        Success a -> a @=? (Report Day Nothing Nothing (Just "tag") Simple)
        (CompletionInvoked _) -> assertFailure "Completion invoked"

testReportType (string, reportType) =
    let result = runCliParser ["report", "-t", string]
    in case result of
        Failure (ParserFailure _) -> assertFailure "parse fail: report"
        Success a -> a @=? (Report Day Nothing Nothing Nothing reportType)
        (CompletionInvoked _) -> assertFailure "Completion invoked"


--------------------------------------------------------------------------------
-- Current
--

testCurrent =
    let result = runCliParser ["current"]
    in case result of
        Failure (ParserFailure _) -> assertFailure "parse fail: current"
        Success a -> a @=? Current
        (CompletionInvoked _) -> assertFailure "Completion invoked"

