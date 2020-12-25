`timescale 1ns / 1ps
`include "../header/Interfaces.vh"
`include "../header/testbench_settings.vh"
`include "../header/test_set.vh"

// ������� ��� ������ ���� ������������ ��������� �����
function automatic string find_file_path(input string file_full_name);
    int str_len = file_full_name.len();
    str_len--;
    while (file_full_name.getc(str_len) != "/") begin
        str_len--;
    end
    return file_full_name.substr(0, str_len); 
endfunction

// ---------------------------------------------------------------
//---------- ��������� ��������� ��� ��������� UART --------------
// ---------------------------------------------------------------
module UART_to_AXIS_tb();
    integer f_result;
    integer f_log;
    
    logic clk = 1'b0;
    logic resetn = 1'b0;
    
    // mailbox ��� ������
    mailbox input_data_mb = new();
    mailbox output_data_mb = new();
    
    // mailbox ��� ������ ��������
    mailbox input_parity_err_mb = new();
    mailbox output_parity_err_mb = new();    
    
    logic [BIT_PER_WORD-1:0] data_array[DATA_WORDS_NUMB], result_data_array[DATA_WORDS_NUMB];  // ������ ������ ��� ��������
    logic parity_err_array [DATA_WORDS_NUMB], result_parity_err_array [DATA_WORDS_NUMB];       // ����� ��������� ������ ��������

// ---------------------------------------------------------------------------------     
    // ����������
    AXIS_intf axis(clk, resetn);
    UART_intf
    #(
        .BIT_RATE(BIT_RATE),    
        .BIT_PER_WORD(BIT_PER_WORD),     
        .PARITY_BIT(PARITY_BIT),       
        .STOP_BITS_NUM(STOP_BITS_NUM)
     )
     uart(resetn);
// ---------------------------------------------------------------------------------            
    // ����������� ������ 
    UART_RX_to_AXIS
    #(
        .CLK_FREQ(CLK_FREQ),       
        .BIT_RATE(BIT_RATE),    
        .BIT_PER_WORD(BIT_PER_WORD),     
        .PARITY_BIT(PARITY_BIT),       
        .STOP_BITS_NUM(STOP_BITS_NUM)    
    )
    DUT
    (
        .axis_port(axis.Master),
        .uart_port(uart.RX_Mod)   
    );
    
// ---------------------------------------------------------------------------------            
// ������������ ��������� ������� 
    initial forever
        #(1000.0 / 2 / CLK_FREQ) clk = ~clk; 

// ---------------------------------------------------------------------------------                
// ������ ������� ������
    initial 
        #RESET_DEASSERT_DELAY resetn = 1'b1; 
        
// ---------------------------------------------------------------------------------        
// �������� �������� �������� � ������ ��������
    initial begin
        // �������� �������� ��������
        for(int i = 0; i < DATA_WORDS_NUMB; i++) begin
            data_array[i] = $urandom_range(2**BIT_PER_WORD - 1, 0);      
            if ( $urandom_range(99, 0) > PARITY_ERR_PROB )
                parity_err_array[i] = 1'b0;
            else
                parity_err_array[i] = 1'b1;        
        end
        
        fork // ������ ��������� �������� ������ � uart � ������ �� axis
            uart.get_forever_from_mailbox(input_data_mb, input_parity_err_mb);
            axis.put_forever_to_mailbox(output_data_mb, output_parity_err_mb);
        join_none
        
        // ������ � mailbox
        for(int i = 0; i < DATA_WORDS_NUMB; i++) begin
            #($urandom_range(DATA_MAX_DELAY, DATA_MIN_DELAY));
            input_data_mb.put(data_array[i]);
            input_parity_err_mb.put(parity_err_array[i]); 
        end
        
        // ������ ������ �� � mailbox
        for(int i = 0; i < DATA_WORDS_NUMB; i++) begin
            output_data_mb.get(result_data_array[i]);
            output_parity_err_mb.get(result_parity_err_array[i]); 
        end
        
        $finish;        
    end
    
// ---------------------------------------------------------------------------------        
// ��������� ����������� �������������
     final begin
        automatic bit test_result = 1;
        automatic string file_path = find_file_path(`__FILE__);
        f_result = $fopen({file_path, "../../log_uart_rx_test/Test_Results.txt"}, "a");
        f_log = $fopen({file_path, "../../log_uart_rx_test/Test_Logs.txt"}, "a");
        
        for (int i = 0; i < DATA_WORDS_NUMB; i++) begin 
            // ��������� ���������� ������
            if (result_data_array[i] != data_array[i]) begin
                $display("Data words number %d not match! Gold value: %h. Result value: %h.", i, data_array[i], result_data_array[i]);
                $fdisplay(f_log, "Data words number %d not match! Gold value: %h. Result value: %h.", i, data_array[i], result_data_array[i]);
                test_result = 0;
            end
            
            // ��������� ��� ��������
            if (PARITY_BIT != 0) begin
                if(parity_err_array[i] != result_parity_err_array[i])
                    $display("Parite error bits in word number %d not match! Gold value: %h. Result value: %h.", i, parity_err_array[i], result_parity_err_array[i]);
                    $fdisplay(f_log, "Parite error bits in word number %d not match! Gold value: %h. Result value: %h.", i, parity_err_array[i], result_parity_err_array[i]);
                    test_result = 0;  
            end
        end
        // ����� ����������� ������������
        $display("-------------------------------------");
        if (test_result) begin
            $display("------------- TEST PASS -------------");
            $fdisplay(f_result, "TEST PASS");
        end else begin
            $display("------------- TEST FAIL -------------");
            $fdisplay(f_result, "TEST FAIL");
        end
        $display("-------------------------------------");
        
        $fclose(f_result);
        $fclose(f_log);    
     end
     
     
endmodule
