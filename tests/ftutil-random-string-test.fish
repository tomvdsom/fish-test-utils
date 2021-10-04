@echo === ftutil-random-string ===
# Manual sourcing, and no erase/emptying fn's & vars - testing one util at-a-time.
source (dirname (status dirname))"/functions/ftutil-random-string.fish"

set _created_1 (ftutil-random-string)
@test "Creates a string" -n $_created_1
@test "Of length 22" (string length -- $_created_1) -eq 22
@test "Randomly (1/2)" (set _created_2 (ftutil-random-string)) $_created_2 != $_created_1
@test "Randomly (2/2)" (set _created_3 (ftutil-random-string)) (test $_created_3 != $_created_2; and test $_created_3 != $_created_1) $status -eq 0
