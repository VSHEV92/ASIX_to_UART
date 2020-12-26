# --------------------------------------------------------------
# ----- C����� ��� ��������������� ������� ���� ������ ---------
# --------------------------------------------------------------

# -----------------------------------------------------------
# ��������� ��� �������� �����������
proc check_test_results {Log_Dir_Name} {
	set Verification_Result 1
	# ��������� ���� ����
	set fileID [open $Log_Dir_Name/Test_Results.txt r]
	set file_data [read $fileID]
	close $fileID
	# ��������� ���� �� ������
	set data [split $file_data "\n"]
	foreach line $data {
		if {[string length $line] && [string first "FAIL" $line] != -1} {
			set Verification_Result 0	
			set message $Log_Dir_Name
			append message ": \"" $line "\""
			puts $message
		}
	}
	return $Verification_Result	
}

# -----------------------------------------------------------
# �������� ������
set Verification_Result 1

# ������ ������
source tcl/run_uart_tx_tests.tcl
source tcl/run_uart_rx_tests.tcl
source tcl/run_uart_loop_tests.tcl

# �������� �����������
puts ""

set Log_Dir_Name log_uart_tx_test
set Verification_Result [check_test_results $Log_Dir_Name]

set Log_Dir_Name log_uart_rx_test
set Verification_Result [check_test_results $Log_Dir_Name]

set Log_Dir_Name log_uart_loop_test
set Verification_Result [check_test_results $Log_Dir_Name]

# ����� �����������
puts ""
if { $Verification_Result } {
	puts "-------------------------------------------"
	puts "--------- VERIFICATION SUCCESSED ----------"
	puts "-------------------------------------------"
} else {
	puts "-------------------------------------------"
	puts "---------- VERIFICATION FAILED ------------"
	puts "-------------------------------------------"
}



