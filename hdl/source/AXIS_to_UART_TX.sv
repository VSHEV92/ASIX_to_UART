`timescale 1ns / 1ps
`include "../header/Interfaces.vh"

// ������ ��������� ����� axi-stream ������� � ������ ���������� ������ ��
// uart ���������� 

module AXIS_to_UART_TX
#(
    parameter int CLK_FREQ = 100,       // �������� ������� � MHz
    parameter int BIT_RATE = 115200,    // �������� ������ � ���/�
    parameter int BIT_PER_WORD = 8,     // ����� ��� � ����� ����� ������
    parameter int PARITY_BIT = 0,       // ��� ���������: 0 - none, 1 - odd, 2 - even
    parameter int STOP_BITS_NUM = 1     // ����� ����-���: 1 ��� 2
)
(
    AXIS_intf.Slave axis_port,     //  axi-stream ���������
    UART_intf.TX_Mod uart_port     //  uart ���������
);

// -----------------------------------------------------------------------------    
enum logic[2:0] {IDLE, START, DATA, PARITY, STOP1, STOP2} State, Next_State;

localparam int Cycle_per_Period = CLK_FREQ * 10e6 / BIT_RATE;

logic [17:0] Clk_Count;
logic Clk_Count_En, Clk_Count_Done;

logic [3:0] Bit_Count;
logic Bit_Count_Done;

logic [BIT_PER_WORD-1:0] Data;

logic Parity_Value, Uart_Out;

// -----------------------------------------------------------------------------    
// ������� �������
always_ff @(posedge axis_port.aclk)
    if(!axis_port.aresetn)
        Data <= 'b0;
    else if (axis_port.tvalid && axis_port.tready)
        Data <= axis_port.tdata;

// -----------------------------------------------------------------------------    
// ���������� ���� ��������
always_comb 
    unique case(PARITY_BIT) 
        0: Parity_Value = 'b0;
        1: Parity_Value = ~(^Data[BIT_PER_WORD-1:0]);  // xor ��� ������ 
        2: Parity_Value = ^Data[BIT_PER_WORD-1:0]; 
    endcase       
       
// -----------------------------------------------------------------------------    
// ������� ����� ������
always_ff @(posedge axis_port.aclk) begin
    if(!axis_port.aresetn)
        Clk_Count <= 'b0;
    else if(Clk_Count_En) begin
        Clk_Count <= Clk_Count + 1;
        if (Clk_Count == Cycle_per_Period)
            Clk_Count <= 'b0;
    end    
end        
assign Clk_Count_Done = (Clk_Count == Cycle_per_Period) ? 1'b1 : 1'b0; 

// -----------------------------------------------------------------------------    
// ������� ����� �������� ���
always_ff @(posedge axis_port.aclk) begin
    if(!axis_port.aresetn)
        Bit_Count <= 'b0;
    else if(Clk_Count_Done && State == DATA) begin
        Bit_Count <= Bit_Count + 1;
        if (Bit_Count == BIT_PER_WORD-1)
            Bit_Count <= 'b0;
    end    
end        
assign Bit_Count_Done = (Bit_Count == BIT_PER_WORD-1 && Clk_Count_Done) ? 1'b1 : 1'b0; 

// -----------------------------------------------------------------------------    
// ���� ������ ������
always_ff @(posedge axis_port.aclk) begin
    if(!axis_port.aresetn)
        uart_port.TX <= 'b1;
    else 
        uart_port.TX <= Uart_Out;        
end        
assign axis_port.tready = (State == IDLE) ? 1'b1 : 1'b0;

// -----------------------------------------------------------------------------    
// ������� ���������

// ����� ���������
always_ff @(posedge axis_port.aclk) 
    if(!axis_port.aresetn)
        State <= IDLE;
    else
        State <= Next_State;

// ���������� �������� ��������
always_comb
    unique case(State)
        IDLE: begin
            Clk_Count_En = 1'b0;
            Uart_Out = 1'b1;
        end
    
        START: begin
            Clk_Count_En = 1'b1;
            Uart_Out = 1'b0;
        end
    
        DATA: begin
            Clk_Count_En = 1'b1;
            Uart_Out = Data[Bit_Count];
        end
        
        PARITY: begin
            Clk_Count_En = 1'b1;
            Uart_Out = Parity_Value;
        end
        
        STOP1, STOP2: begin
            Clk_Count_En = 1'b1;
            Uart_Out = 1'b1;
        end
    endcase

// ���������� ���������� ���������
always_comb
    unique case(State)
        IDLE: // �������� ������ ��������
            Next_State = (axis_port.tvalid) ? START : IDLE;
            
        START: // ������ �����-����
            Next_State = (Clk_Count_Done) ? DATA : START; 
             
        DATA: // ������ ��� ������ 
            if (Bit_Count_Done)
                if (PARITY_BIT)
                    Next_State = PARITY;
                else
                    Next_State = STOP1;  
            else
                Next_State = DATA; 
                             
        PARITY: // ������ ���� ��������
            Next_State = (Clk_Count_Done) ? STOP1 : PARITY; 
            
        STOP1: // ������ ������� ����-����
            if (Clk_Count_Done)
                if (PARITY_BIT == 1)
                    Next_State = IDLE;
                else
                    Next_State = STOP2;  
            else
                Next_State = STOP1; 
            
        STOP2: // ������ ������� ����-����
            Next_State = (Clk_Count_Done) ? IDLE : STOP2;        
    endcase
    
endmodule
