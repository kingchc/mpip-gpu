set test_targ "./testing/$test"
set timeout 30
global expect_out


proc checkOutput { text type } {
  global outFile
  global test
  spawn cat $outFile
  expect { 
     -re $text {send_user "found $type $text\n"}
     timeout { fail "$test timed out\n" }
     eof     { fail "$test $type $text\n" }
    }
}


proc runTest { } {
  global launch pool rmpool procs test_targ test expect_out env

  case "$launch" in {
      { "prun" } { 
        set pre_args "-p$pool"
  	set pre_procs "-n$procs"
        send_user "$launch $pre_args $pre_procs $test_targ \n"
        spawn -noecho $launch $pre_args $pre_procs $test_targ 
  	}
      { "poe" } { 
        set env(MP_PROCS) "$procs"
#        send_user "set MP_PROCS to $procs=$env(MP_PROCS)"
        set env(MP_NODES) 1
        set env(MP_RMPOOL) $rmpool
        send_user "$launch $test_targ \n"
        spawn -noecho $launch $test_targ 
  	}
  }
  
  set expect_out(1,string) ""
  expect { 
     -re "mpiP: Storing mpiP output in .\./(.*\.mpiP)\](.*)"   { }
     timeout { fail "$test timed out" }
     eof     { fail "$test failed" }
  
     }

#  send_user "$expect_out(buffer)"
}


proc checkSource { } {

  global expect_out
  global source_check_file
  global test outFile

  runTest

#  set buflen  [string length $expect_out(buffer)]
#  set arrlen [array size expect_out]
#  set arrnames [array names expect_out]
#  send_user "expect_buffer length $buflen  - arrlen = $arrlen, arrnames = $arrnames\n" 
  if { [string length $expect_out(buffer)] == 0 || [array size expect_out] < 3 \
      || [string length $expect_out(1,string)] == 0 } {
    fail "Couldn't find mpiP report file."
    return 
  }

  set outFile $expect_out(1,string)
  send_user "Found mpiP report file: $outFile\n"
  set expect_out(1) ""
  set expect_out(buffer) ""

  source $source_check_file
  pass "$test passed"
}
