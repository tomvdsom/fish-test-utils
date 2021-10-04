@echo === ftutil-erase-variables ===
# Manual sourcing, and no erase/emptying fn's & vars - testing one util at-a-time.
source (dirname (status dirname))"/functions/ftutil-erase-variables.fish"
source (dirname (status dirname))"/functions/ftutil-eval-nl.fish"
source (dirname (status dirname))"/functions/ftutil-eval-nl-err.fish"

ftutil-eval-nl --short-cmd
ftutil-eval-nl-err --short-cmd

# Cleanup
function _ftutil_erase_variables_test_cleanup --on-event fish_exit
    set --erase --universal _ftutil_erase_variables_test_a_variable
end

#
# Helpers
function _show-long
    set --local var_name $argv[1]
    set --local var_scope $argv[2] # local, global or universal
    set --local var_exported $argv[3]
    set --local var_values $argv[4..]

    set --local var_exported_str

    if test $var_exported = u
        set var_exported_str unexported
    else # x
        set var_exported_str exported
    end
    echo -n -- "\$$var_name: set in $var_scope scope, $var_exported_str"
    if count $var_values >/dev/null
        and test (string length -- $var_values[1]) -ne 0
        echo -- ", with "(count $var_values)" elements"
        set --local index 0
        for v in $var_values
            set index (math $index + 1)
            echo -- "\$$var_name"'['"$index"']: |'"$v"'|'
        end
    else
        echo -- ', with 0 elements'
    end
end

#
# Tests
@echo ' • basic usage: no erasing'
ftutil-erase-variables
@test 'Erase nothing (no regex) is fine (1/3)' (en ftutil-erase-variables 2>/dev/null | string collect) = ''
@test 'Erase nothing (no regex) is fine (2/3)' (ene ftutil-erase-variables 2>&1 >/dev/null | string collect) = ''
@test 'Erase nothing (no regex) is fine (3/3)' (ftutil-erase-variables) $status -eq 0
@test 'Erase nothing (no match) is fine (1/3)' (en ftutil-erase-variables this_variable_really_does_not_exist 2>/dev/null | string collect) = ''
@test 'Erase nothing (no match) is fine (2/3)' (ene ftutil-erase-variables this_variable_really_does_not_exist 2>&1 >/dev/null | string collect) = ''
@test 'Erase nothing (no match) is fine (3/3)' (ftutil-erase-variables this_variable_really_does_not_exist) $status -eq 0

@echo ' • basic usage: one regex, one var, one value'
function _test
    set _a_variable A
    @test 'Erase a function(-local) scoped variable (1/2)' (set --show --long _a_variable | string collect) = (_show-long _a_variable local u A | string collect)
    ftutil-erase-variables _a_variable
    @test 'Erase a function(-local) scoped variable (2/3)' $status -eq 0
    @test 'Erase a function(-local) scoped variable (3/3)' (en set --show --long _a_variable | string collect) = ''
end
_test

set --local _a_variable A
@test 'Erase a local scoped variable (1/2)' (set --show --long _a_variable | string collect) = (_show-long _a_variable local u A | string collect)
ftutil-erase-variables _a_variable
@test 'Erase a local scoped variable (2/2)' (en set --show --long _a_variable | string collect) = ''

set --global --export _a_variable A
@test 'Erase a global scoped (& exported) variable (1/2)' (set --show --long _a_variable | string collect) = (_show-long _a_variable global x A | string collect)
ftutil-erase-variables _a_variable
@test 'Erase a global scoped (& exported) variable (2/2)' (en set --show --long _a_variable | string collect) = ''

set --universal _ftutil_erase_variables_test_a_variable U
@test 'Erase a universal scoped variable (1/2)' (set --show --long _ftutil_erase_variables_test_a_variable | string collect) = (_show-long _ftutil_erase_variables_test_a_variable universal u U | string collect)
ftutil-erase-variables _ftutil_erase_variables_test_a_variable >/dev/null
@test 'Erase a universal scoped variable (2/2)' (en set --show --long _ftutil_erase_variables_test_a_variable | string collect) = ''

@echo ' • same variable name, different scopes'
function _test
    set _ftutil_erase_variables_test_a_variable f
    set --local _ftutil_erase_variables_test_a_variable l
    set --global _ftutil_erase_variables_test_a_variable g
    set --universal _ftutil_erase_variables_test_a_variable U
    @test 'Same name different scope variable (1/2)' (set --show --long _ftutil_erase_variables_test_a_variable | string collect) = '$_ftutil_erase_variables_test_a_variable: set in local scope, unexported, with 1 elements
$_ftutil_erase_variables_test_a_variable[1]: |l|
$_ftutil_erase_variables_test_a_variable: set in global scope, unexported, with 1 elements
$_ftutil_erase_variables_test_a_variable[1]: |g|
$_ftutil_erase_variables_test_a_variable: set in universal scope, unexported, with 1 elements
$_ftutil_erase_variables_test_a_variable[1]: |U|'
    ftutil-erase-variables _ftutil_erase_variables_test_a_variable >/dev/null
    @test 'Same name different scope variable (2/2)' (en set --show --long _ftutil_erase_variables_test_a_variable | string collect) = ''
end
_test

@echo ' • same variable name, multiple shadowed local scopes'
set --erase --local _a_variable
begin
    set --local _a_variable 1
    begin
        set --local _a_variable 2
        if true
            set --local _a_variable 3
            @test 'Only inner local scope inspectable via `set --show`' (en set --show --long _a_variable | string collect) = (_show-long _a_variable local u 3 | string collect)
            ftutil-erase-variables _a_variable
            @test 'All local scopes of variable erased' (en set --show --long _a_variable | string collect) = ''
        end
    end
end

@echo ' • Saving variables'
begin
    set --local expected '_a_variable|local|unexported|value'
    set --local _a_variable value
    @test 'Saving simple value variables (1/5) - local & unexported, long opt' (en ftutil-erase-variables --save-variables=local _a_variable | string collect) = $expected
    @test 'Saving simple value variables (2/5) - local & unexported, long opt' (en set --show --long _a_variable | string collect) = ''
    set --local _a_variable value
    @test 'Saving simple value variables (3/5) - local & unexported, short opt' (en ftutil-erase-variables -slocal _a_variable | string collect) = $expected
    @test 'Saving simple value variables (4/5) - local & unexported, short opt' (en set --show --long _a_variable | string collect) = ''
end
begin
    set --local --export _a_variable value
    @test 'Saving simple value variables (5/5) - local & exported' (en ftutil-erase-variables --save-variables=local _a_variable | string collect) = '_a_variable|local|exported|value'
end
begin
    set --local _a_variable v1 v2 v3
    @test 'Saving simple multi-valued variable (local) (1/3)' (count $_a_variable) -eq 3
    @test 'Saving simple multi-valued variable (local) (2/3)' (en ftutil-erase-variables --save-variables=local _a_variable | string collect) = '_a_variable|local|unexported|v1,v2,v3'
    @test 'Saving simple multi-valued variable (local) (3/3)' (en set --show --long _a_variable | string collect) = ''
end
begin
    # Complex meaning "harder to get right" (1/2):
    # - space, newline (inside and at the outside of a value), with right-newline - should not be stripped.
    # - empty value (represented by "empty string" placeholder - though technically cheating);
    # - non-ascii represenatable value (sum-symbol)
    set --local _a_variable v\ a\n\|\tuΣ-1 '' \ v\ a\n\|\tuΣ,3\n
    @test 'Saving complex multi-valued variable (local) (1/2)' (count $_a_variable) -eq 3
    @test 'Saving complex multi-valued variable (local) (2/2)' (en ftutil-erase-variables --save-variables=local _a_variable | string collect) = '_a_variable|local|unexported|v_20_a_0A_7C_09_u_CE_A3_2D_31_,,_20_v_20_a_0A_7C_09_u_CE_A3_2C_33_0A_'
end
begin
    # Complex meaning "harder to get right" (2/2):
    # - All bytes (0-255) encoded correctly ... (though pretty useless for nul / 0-byte, unless for debugging unexpected nulls).
    #
    # Not concerned with correct UTF-8 values here, just respresentability of possible byte-values.
    set --local x (string join '' (for i in (seq 0 255); printf '\\X%x' $i; end))
    eval set --local _a_variable $x
    @test 'Saving complex value can represent 0-255 byte-value' (en ftutil-erase-variables --save-variables=local _a_variable | string collect) = '_a_variable|local|unexported|_00_01_02_03_04_05_06_07_08_09_0A_0B_0C_0D_0E_0F_10_11_12_13_14_15_16_17_18_19_1A_1B_1C_1D_1E_1F_20_21_22_23_24_25_26_27_28_29_2A_2B_2C_2D_2E_2F_30_31_32_33_34_35_36_37_38_39_3A_3B_3C_3D_3E_3F_40_41_42_43_44_45_46_GHIJKLMNOPQRSTUVWXYZ_5B_5C_5D_5E___60_abcdefghijklmnopqrstuvwxyz_7B_7C_7D_7E_7F_80_81_82_83_84_85_86_87_88_89_8A_8B_8C_8D_8E_8F_90_91_92_93_94_95_96_97_98_99_9A_9B_9C_9D_9E_9F_A0_A1_A2_A3_A4_A5_A6_A7_A8_A9_AA_AB_AC_AD_AE_AF_B0_B1_B2_B3_B4_B5_B6_B7_B8_B9_BA_BB_BC_BD_BE_BF_C0_C1_C2_C3_C4_C5_C6_C7_C8_C9_CA_CB_CC_CD_CE_CF_D0_D1_D2_D3_D4_D5_D6_D7_D8_D9_DA_DB_DC_DD_DE_DF_E0_E1_E2_E3_E4_E5_E6_E7_E8_E9_EA_EB_EC_ED_EE_EF_F0_F1_F2_F3_F4_F5_F6_F7_F8_F9_FA_FB_FC_FD_FE_FF_'
end
begin
    set --local --export _a_variable # Empty variable
    @test 'Saving empty value variables (local) (1/2)' (en set --show --long _a_variable | string collect) = (_show-long _a_variable local x | string collect)
    @test 'Saving empty value variables (local) (2/2)' (en ftutil-erase-variables --save-variables=local _a_variable | string collect) = '_a_variable|local|exported|'
end

set --global _a_variable v\ a\n\|\tuΣ-1 '' \ v\ a\n\|\tuΣ,3\n
@test 'Saving global (1/6)' (count $_a_variable) -eq 3
@test 'Saving global (2/6)' (en ftutil-erase-variables --save-variables=global _a_variable | string collect) = '_a_variable|global|unexported|v_20_a_0A_7C_09_u_CE_A3_2D_31_,,_20_v_20_a_0A_7C_09_u_CE_A3_2C_33_0A_'
@test 'Saving global (3/6)' (en set --show --long _a_variable | string collect) = ''
set --global --export _a_variable value
@test 'Saving global (4/6)' (count $_a_variable) -eq 1
@test 'Saving global (5/6)' (en ftutil-erase-variables --save-variables=global _a_variable | string collect) = '_a_variable|global|exported|value'
@test 'Saving global (6/6)' (en set --show --long _a_variable | string collect) = ''

set --universal _ftutil_erase_variables_test_a_variable v\ a\n\|\tuΣ-1 '' \ v\ a\n\|\tuΣ,3\n
@test 'Saving universal (1/6)' (count $_ftutil_erase_variables_test_a_variable) -eq 3
@test 'Saving universal (2/6)' (en ftutil-erase-variables --save-variables=universal _ftutil_erase_variables_test_a_variable | string collect) = '_ftutil_erase_variables_test_a_variable|universal|unexported|v_20_a_0A_7C_09_u_CE_A3_2D_31_,,_20_v_20_a_0A_7C_09_u_CE_A3_2C_33_0A_'
@test 'Saving universal (3/6)' (en set --show --long _ftutil_erase_variables_test_a_variable | string collect) = ''
set --universal --export _ftutil_erase_variables_test_a_variable value
@test 'Saving universal (4/6)' (count $_ftutil_erase_variables_test_a_variable) -eq 1
@test 'Saving universal (5/6)' (en ftutil-erase-variables --save-variables=universal _ftutil_erase_variables_test_a_variable | string collect) = '_ftutil_erase_variables_test_a_variable|universal|exported|value'
@test 'Saving universal (6/6)' (en set --show --long _a_variable | string collect) = ''

@echo ' • Scoped saving doesn\'t save other scopes'
set --local set_all_scopes 'set --universal _ftutil_erase_variables_test_a_variable U
set --global _ftutil_erase_variables_test_a_variable G
set --local _ftutil_erase_variables_test_a_variable L'

eval $set_all_scopes
@test 'All scopes visible for erasing & saving' (set --show --long _ftutil_erase_variables_test_a_variable | string collect) = '$_ftutil_erase_variables_test_a_variable: set in local scope, unexported, with 1 elements
$_ftutil_erase_variables_test_a_variable[1]: |L|
$_ftutil_erase_variables_test_a_variable: set in global scope, unexported, with 1 elements
$_ftutil_erase_variables_test_a_variable[1]: |G|
$_ftutil_erase_variables_test_a_variable: set in universal scope, unexported, with 1 elements
$_ftutil_erase_variables_test_a_variable[1]: |U|'

@test 'Scoped saving, universal only be default' (en ftutil-erase-variables _ftutil_erase_variables_test_a_variable | string collect --no-trim-newlines) = _ftutil_erase_variables_test_a_variable\|universal\|unexported\|U\n\n
eval $set_all_scopes
@test 'Scoped saving, universal only' (en ftutil-erase-variables --save-variables=universal _ftutil_erase_variables_test_a_variable | string collect) = '_ftutil_erase_variables_test_a_variable|universal|unexported|U'
eval $set_all_scopes
@test 'Scoped saving, global only' (en ftutil-erase-variables --save-variables=global _ftutil_erase_variables_test_a_variable | string collect) = '_ftutil_erase_variables_test_a_variable|global|unexported|G'
eval $set_all_scopes
@test 'Scoped saving, local only (`local` scope saving only useful for debugging)' (en ftutil-erase-variables --save-variables=local _ftutil_erase_variables_test_a_variable | string collect) = '_ftutil_erase_variables_test_a_variable|local|unexported|L'
eval $set_all_scopes
@test 'Scoped saving, mixed (universal & global)' (en ftutil-erase-variables --save-variables=universal,global _ftutil_erase_variables_test_a_variable | string collect --no-trim-newlines) = _ftutil_erase_variables_test_a_variable\|global\|unexported\|G\n_ftutil_erase_variables_test_a_variable\|universal\|unexported\|U\n\n
eval $set_all_scopes
@test 'Scoped saving, mixed (local & global), short opt' (en ftutil-erase-variables -slocal,global _ftutil_erase_variables_test_a_variable | string collect) = '_ftutil_erase_variables_test_a_variable|local|unexported|L
_ftutil_erase_variables_test_a_variable|global|unexported|G'
eval $set_all_scopes
@test 'Scoped saving, all, multiple flags' (en ftutil-erase-variables -sl,g,u _ftutil_erase_variables_test_a_variable | string collect) = '_ftutil_erase_variables_test_a_variable|local|unexported|L
_ftutil_erase_variables_test_a_variable|global|unexported|G
_ftutil_erase_variables_test_a_variable|universal|unexported|U'

@echo ' • Scoped saving all scopes'
eval $set_all_scopes
@test 'Scoped saving, all, using `all` virtual scope (1/2)' (en ftutil-erase-variables -sall _ftutil_erase_variables_test_a_variable | string collect) = '_ftutil_erase_variables_test_a_variable|local|unexported|L
_ftutil_erase_variables_test_a_variable|global|unexported|G
_ftutil_erase_variables_test_a_variable|universal|unexported|U'
eval $set_all_scopes
@test 'Scoped saving, all, using `all` virtual scope (2/2)' (en ftutil-erase-variables -sa _ftutil_erase_variables_test_a_variable | string collect) = '_ftutil_erase_variables_test_a_variable|local|unexported|L
_ftutil_erase_variables_test_a_variable|global|unexported|G
_ftutil_erase_variables_test_a_variable|universal|unexported|U'
eval $set_all_scopes
@test 'Scoped saving, all and specific scopes can be mixed - though effectively `all` (1/2)' (en ftutil-erase-variables -sa,l _ftutil_erase_variables_test_a_variable | string collect) = '_ftutil_erase_variables_test_a_variable|local|unexported|L
_ftutil_erase_variables_test_a_variable|global|unexported|G
_ftutil_erase_variables_test_a_variable|universal|unexported|U'
eval $set_all_scopes
@test 'Scoped saving, all and specific scopes can be mixed - though effectively `all` (2/2)' (en ftutil-erase-variables -sl,a,g,u _ftutil_erase_variables_test_a_variable | string collect) = '_ftutil_erase_variables_test_a_variable|local|unexported|L
_ftutil_erase_variables_test_a_variable|global|unexported|G
_ftutil_erase_variables_test_a_variable|universal|unexported|U'

@echo ' • No(t) saving any scopes'
@test 'None virtual scope is mutually exclusive with real scopes (1/3)' (en ftutil-erase-variables --save-variables=none,global this_variable_really_does_not_exist 2>/dev/null | string collect) = ''
@test 'None virtual scope is mutually exclusive with real scopes (2/3)' (en ftutil-erase-variables --save-variables=none,global this_variable_really_does_not_exist 2>&1 >/dev/null | string collect) = 'ftutil-erase-variables: Error, flag `--save-variables` (comma separated) values, cannot combine n / none with any other value.\n  Values: none,global'
@test 'None virtual scope is mutually exclusive with real scopes (3/3)' (ftutil-erase-variables --save-variables=none,global this_variable_really_does_not_exist >/dev/null 2>&1) $status -eq 1

eval $set_all_scopes
@test 'No saving, using `none` virtual scope (1/2)' (en ftutil-erase-variables --save-variables=none _ftutil_erase_variables_test_a_variable | string collect) = ''
eval $set_all_scopes
@test 'No saving, using `none` virtual scope (2/2)' (en ftutil-erase-variables --save-variables=n _ftutil_erase_variables_test_a_variable | string collect) = ''
@test 'No saving still erases' (en set --show --long _ftutil_erase_variables_test_a_variable | string collect) = ''

set --local _flag_s X
set --local _flag_save_variables X
@test 'argparse set flags in implementation don\'t leak' (en ftutil-erase-variables --save-variables=all '_flag_.*' | string collect) = '_flag_s|local|unexported|X
_flag_save_variables|local|unexported|X'

@echo ' • Regex match & multiple args for matching'
set --local _a_variable A
set --local _b_variable B
@test 'Matching variables (regex arg) (1/2)' (ftutil-erase-variables --save-variables=none '_._variable') $status -eq 0
@test 'Matching variables (regex arg) (2/2)' (en set --show --long _a_variable _b_variable | string collect) = ''
set --local _a_variable A
set --local _b_variable B
@test 'Matching variables - multiple args (regexes) given (1/2)' (ftutil-erase-variables --save-variables=none _a_variable _b_variable) $status -eq 0
@test 'Matching variables - multiple args (regexes) given (2/2)' (en set --show --long _a_variable _b_variable | string collect) = ''

#
# Helpers
#
# - _ftutil-erase-variables-collect-encoded-values extracted & slightly modified from: `functions/_ftutil-log-args.fish`.
#
@test '`⃨-collect-encoded-values` empty' (begin; _ftutil-erase-variables-collect-encoded-values; echo -n x; end | string collect --no-trim-newlines) = x
@test '`⃨-collect-encoded-values` 1 arg' (en _ftutil-erase-variables-collect-encoded-values one | string collect --no-trim-newlines) = one\n
@test '`⃨-collect-encoded-values` logs to stdout, nothing to stderr' (begin; _ftutil-erase-variables-collect-encoded-values one 2>&1 >/dev/null; echo -n x; end | string collect --no-trim-newlines) = x
@test '`⃨-collect-encoded-values` N arg' (en _ftutil-erase-variables-collect-encoded-values one two three | string collect) = one,two,three
@test '`⃨-collect-encoded-values` whitespace & newlines' (en _ftutil-erase-variables-collect-encoded-values o\ n\ e t\nwo \tthree | string collect) = 'o_20_n_20_e,t_0A_wo,_09_three'
@test '`⃨-collect-encoded-values`empty args (1/2) - as an arg' (en _ftutil-erase-variables-collect-encoded-values '' | string collect) = ""
@test '`⃨-collect-encoded-values` empty args (2/2) - in between' (en _ftutil-erase-variables-collect-encoded-values be '' tween | string collect) = "be,,tween"
@test '`⃨-collect-encoded-values` two-single-quotes (1/2) - as an arg' (en _ftutil-erase-variables-collect-encoded-values \'\') = _27_27_
@test '`⃨-collect-encoded-values` two-single-quotes (1/2) - in between' (en _ftutil-erase-variables-collect-encoded-values one \'\' three) = 'one,_27_27_,three'
@test '`⃨-collect-encoded-values` newline (1/2) - as arg' (en _ftutil-erase-variables-collect-encoded-values \n) = _0A_
@test '`⃨-collect-encoded-values` newline (2/2) - in between' (en _ftutil-erase-variables-collect-encoded-values one \n three) = "one,_0A_,three"
