// ------------------------------------------------------
//---------- ��������� ��������� ��������� --------------
// ------------------------------------------------------
parameter int CLK_FREQ = 100;              // �������� ������� � MHz  
parameter int RESET_DEASSERT_DELAY = 100;  // ����� ������ ������� ������ ns
parameter int DATA_WORDS_NUMB = 100;      // ����� ������������ ����
parameter int PARITY_ERR_PROB = 7;         // ������ � ������������ ����� � ���������

parameter int DATA_MIN_DELAY = 5*10e4;      // ������������ �������� ����� ��������� ������
parameter int DATA_MAX_DELAY = 10e5;      // ������������ �������� ����� ��������� ������

// ������� ��� ������ ���� ������������ ��������� �����
function automatic string find_file_path(input string file_full_name);
    int str_len = file_full_name.len();
    str_len--;
    while (file_full_name.getc(str_len) != "/") begin
        str_len--;
    end
    return file_full_name.substr(0, str_len); 
endfunction