# CI report — main @ 766cf4938a66014017217bf270ae4c4958aa8052

- run: 28735023183 attempt 1
- outcome: failure
- date: 2026-07-05T08:41:00Z
- url: https://github.com/HugoReel/anchor-ios/actions/runs/28735023183

## build/lint.log

### errors and warnings
```
```

### summary lines
```
```

## build/test-packages.log

### errors and warnings
```
```

### summary lines
```
Test Suite 'All tests' started at 2026-07-05 08:39:51.438.
Test Suite 'All tests' passed at 2026-07-05 08:39:51.439.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
◇ Test run started.
✔ Test run with 87 tests passed after 0.111 seconds.
Test Suite 'All tests' started at 2026-07-05 08:39:52.609.
Test Suite 'All tests' passed at 2026-07-05 08:39:52.609.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
◇ Test run started.
✔ Test run with 8 tests passed after 0.003 seconds.
Test Suite 'All tests' started at 2026-07-05 08:39:53.491.
Test Suite 'All tests' passed at 2026-07-05 08:39:53.491.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
◇ Test run started.
✔ Test run with 13 tests passed after 0.128 seconds.
Test Suite 'All tests' started at 2026-07-05 08:39:54.429.
Test Suite 'All tests' passed at 2026-07-05 08:39:54.429.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
◇ Test run started.
✔ Test run with 7 tests passed after 0.005 seconds.
Test Suite 'All tests' started at 2026-07-05 08:40:01.367.
Test Suite 'All tests' passed at 2026-07-05 08:40:01.367.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
◇ Test run started.
✔ Test run with 9 tests passed after 0.315 seconds.
Test Suite 'All tests' started at 2026-07-05 08:40:16.609.
Test Suite 'All tests' passed at 2026-07-05 08:40:16.610.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.001) seconds
◇ Test run started.
✔ Test run with 3 tests passed after 0.018 seconds.
Test Suite 'All tests' started at 2026-07-05 08:40:22.958.
Test Suite 'All tests' passed at 2026-07-05 08:40:22.958.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.001) seconds
◇ Test run started.
✔ Test run with 10 tests passed after 0.013 seconds.
Test Suite 'All tests' started at 2026-07-05 08:40:24.158.
Test Suite 'All tests' passed at 2026-07-05 08:40:24.158.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.001) seconds
◇ Test run started.
✔ Test run with 4 tests passed after 0.023 seconds.
Test Suite 'All tests' started at 2026-07-05 08:40:25.705.
Test Suite 'All tests' passed at 2026-07-05 08:40:25.705.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
◇ Test run started.
✔ Test run with 16 tests passed after 0.027 seconds.
Test Suite 'All tests' started at 2026-07-05 08:40:28.153.
Test Suite 'All tests' passed at 2026-07-05 08:40:28.154.
	 Executed 0 tests, with 0 failures (0 unexpected) in 0.000 (0.000) seconds
◇ Test run started.
✔ Test run with 13 tests passed after 0.017 seconds.
** TEST SUCCEEDED **
```

## build/app-build.log

### errors and warnings
```
/Users/runner/work/anchor-ios/anchor-ios/App/AppRootView.swift:22:35: error: main actor-isolated property 'onboardingComplete' can not be mutated from a Sendable closure
```

### summary lines
```
** BUILD FAILED **
```

## coverage (per target)
```
ID Name                   # Source Files Coverage           
-- ---------------------- -------------- ------------------ 
0  AnchorCore             32             90.46% (939/1038)  
1  AnchorCoreTests        46             94.56% (1895/2004) 
2  AnchorDesign           9              49.59% (121/244)   
3  AnchorDesignTests      44             83.95% (1161/1383) 
4  AnchorPersistence      5              67.20% (295/439)   
5  AnchorPersistenceTests 39             84.83% (1381/1628) 
6  AnchorPlatform         0              0.00% (0/0)        
7  FeatureCoping          4              11.18% (58/519)    
8  FeatureCopingTests     37             65.96% (1089/1651) 
9  FeatureGoals           6              10.36% (92/888)    
10 FeatureGoalsTests      39             56.26% (1159/2060) 
11 FeatureOnboarding      2              14.23% (36/253)    
12 FeatureOnboardingTests 44             72.23% (1142/1581) 
13 FeatureReflect         7              12.35% (169/1368)  
14 FeatureReflectTests    40             48.89% (1250/2557) 
15 FeatureSettings        3              15.92% (64/402)    
16 FeatureSettingsTests   45             67.96% (1188/1748) 
17 FeatureTimeline        8              12.85% (249/1938)  
18 FeatureTimelineTests   41             44.69% (1457/3260) 
19 FeatureToday           3              18.24% (137/751)   
20 FeatureTodayTests      36             64.30% (1295/2014) 

```
