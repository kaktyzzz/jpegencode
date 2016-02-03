/////////////////////////////////////////////////////////////////////
////                                                             ////
////  JPEG Encoder Core - Verilog                                ////
////                                                             ////
////  Author: David Lundgren                                     ////
////          davidklun@gmail.com                                ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2009 David Lundgren                           ////
////                  davidklun@gmail.com                        ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////


`timescale 1ps / 1ps

`define NULL 0

module jpeg_top_tb;


reg end_of_file_signal;
reg [23:0]data_in;
reg clk;
reg rst;
reg enable;
wire [31:0]JPEG_bitstream;
wire data_ready;
wire [4:0]end_of_file_bitstream_count;
wire eof_data_partial_ready;

reg [31:0]temp_write;

integer output_file;
integer input_file;
integer line;
integer c;



// Unit Under Test 
	jpeg_top UUT (
		.end_of_file_signal(end_of_file_signal),
		.data_in(data_in),
		.clk(clk),
		.rst(rst),
		.enable(enable),
		.JPEG_bitstream(JPEG_bitstream),
		.data_ready(data_ready),
		.end_of_file_bitstream_count(end_of_file_bitstream_count),
		.eof_data_partial_ready(eof_data_partial_ready));



initial
begin : STIMUL 
	output_file = $fopen("out.jpg","wb");
	input_file = $fopen("../../input.txt", "r"); //file contains block 8*8 RGB, row first
	if (input_file == `NULL) begin
		$display("File not found!");
		$finish;
	end
	#1000;
	rst = 1'b1;
	enable = 1'b0;
	end_of_file_signal = 1'b0;
    #10000; 
	rst = 1'b0;
	enable = 1'b1;
	// data_in holds the red, green, and blue pixel values
	// obtained from the .tif image file
	c <= 0;
    while (!$feof(input_file)) begin
		line = $fscanf(input_file, "%h\n", data_in);
		#10000;
		//$display("%b", data_in);
		c = c + 1;
		if (c == 64) begin
			c <= 0;
			#130000;
			enable <= 1'b0;
			#10000;
			enable <= 1'b1;
		end
	end
	
	enable <= 1'b0;
	end_of_file_signal  <= 1'b1;
	#3800000; //Очень аккуратное число!
	
	$fclose(output_file);
	$fclose(input_file);
	$finish;
end // end of stimulus process
	
always
begin : CLOCK_clk
	//this process was generated based on formula: 0 0 ns, 1 5 ns -r 10 ns
	//#<time to next event>; // <current time>
	clk = 1'b0;
	#5000; //0
	clk = 1'b1;
	#5000; //5000
end

always 	@(JPEG_bitstream or data_ready)
begin : JPEG
		if (data_ready==1'b1) 	begin	//изменил, чтобы не выводились нули
			//$writeh(JPEG_bitstream);	
			temp_write[7:0] = JPEG_bitstream[31:24];
			temp_write[15:8] = JPEG_bitstream[23:16];
			temp_write[23:16] = JPEG_bitstream[15:8];
			temp_write[31:24] = JPEG_bitstream[7:0];
			$fwrite(output_file, "%u", temp_write);					
			//$display("%h", JPEG_bitstream);	
		end
end	


endmodule
