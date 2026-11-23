// Verilog HDL for "Beispiel", "Sort_Controllogic" "functional"

module FFT_Controllogic( clk, 
           state, en_alu_addr, en_alu_end, en_alu_loop, en_comp_alu, en_reg_end_inner_loop, en_reg_len, en_reg_k, 
en_reg_omega, en_reg_t, en_write_addr1, en_write_addr2, init_stagepow, mux_alu_addr[1:0], 
mux_alu_loop[1:0], mux_com_inner_loop_addr2,mux_com_inner_loop_eil , mux_comp_alu_data, mux_read_addr, mux_write_addr, reset, shift_stagepow, 
sub_alu_end, ram_wr_en, ram_rd_en, mux_init_addr2[1:0], reset_omega, reset_reg_k, reset_reg_addr2,en_reg_jplus1, en_reg_data1, wr_data1_1, wr_data1_2, wr_data2_1, wr_data2_2,flag_finished);

   parameter SETUP= 3'b000;
   parameter IL1  = 3'b001;
   parameter IL2  = 3'b010;
   parameter ML1  = 3'b011;
   parameter ML2  = 3'b100;
   parameter OL1  = 3'b101;
   parameter HALT = 3'b110;

   input  [2:0] state;
   input clk;

   output       en_alu_addr;
   output       en_alu_end;
   output       en_alu_loop;
   output       en_comp_alu;
   output       en_reg_end_inner_loop;
   output       en_reg_len;
   output       en_reg_k;
   output       en_reg_omega;
   output       en_reg_t;
   output       en_write_addr1;
   output       en_write_addr2;
   output       init_stagepow;
   output       [1:0]mux_alu_addr;
   output       [1:0] mux_alu_loop;
   output       mux_com_inner_loop_addr2;
   output       mux_com_inner_loop_eil;
   output       mux_comp_alu_data;
   output       [1:0]mux_init_addr2;
   output       mux_read_addr;
   output       mux_write_addr;
   output       reset;
   output       shift_stagepow;
   output       sub_alu_end;
   output       ram_wr_en;
   output       ram_rd_en;
   output       reset_omega;
   output       reset_reg_k;
   output       reset_reg_addr2;
   output       en_reg_jplus1;
   output       en_reg_data1;
   output       wr_data1_1;
   output       wr_data1_2;
   output       wr_data2_1;
   output       wr_data2_2;
   output       flag_finished;


   reg       en_alu_addr;
   reg       en_alu_end;
   reg       en_alu_loop;
   reg       en_comp_alu;
   reg		en_reg_end_inner_loop;
   reg		en_reg_len;
   reg       en_reg_k;
   reg       en_reg_omega;
   reg       en_reg_t;
   reg       en_write_addr1;
   reg       en_write_addr2;
   reg       init_stagepow;
   reg       [1:0]mux_alu_addr;
   reg       [1:0] mux_alu_loop;
   reg       mux_comp_alu_data;
   reg       [1:0]mux_init_addr2;
   reg       mux_com_inner_loop_addr2;
   reg       mux_com_inner_loop_eil;
   reg       mux_read_addr;
   reg       mux_write_addr;
   reg       reset;
   reg		shift_stagepow;
   reg       sub_alu_end;
   reg       ram_wr_en;
   reg       ram_rd_en;
   reg       reset_omega;
   reg       reset_reg_k;
   reg       reset_reg_addr2;
   reg       en_reg_jplus1;
   reg       en_reg_data1;
   reg       wr_data1_1;
   reg       wr_data1_2;
   reg       wr_data2_1;
   reg       wr_data2_2;
   reg       flag_finished;

   reg       pipeline_level1;
   reg       pipeline_level2;
   reg       pipeline_level3;
   reg       pipeline_level4;
   reg       pipeline_level5;
   reg       pipeline_level6;
   reg       pipeline_level7;
   reg       pipeline_level8;

   reg       pipeline_level_ML1;
   reg       pipeline_level_ML2;
   reg       pipeline_level_ML3;

   reg       delay_signal_first_iteration_il_in;
   reg       delay_signal_first_iteration_il_out;

/*
   always@(posedge reset)
	begin
       pipeline_level1 <= 1'b0;
       pipeline_level2 <= 1'b0;
       pipeline_level3 <= 1'b0;
       pipeline_level4 <= 1'b0;
       pipeline_level5 <= 1'b0;
       pipeline_level6 <= 1'b0;
       pipeline_level7 <= 1'b0;
       pipeline_level8 <= 1'b0;

       pipeline_level_ML2 <= 1'b0;
       pipeline_level_ML3 <= 1'b0;

       delay_signal_first_iteration_il_in <= 1'b0;
       delay_signal_first_iteration_il_out <= 1'b0;
	end*/
   always@(posedge clk) // simple shift register
     begin
       //pipeline_level2 <= pipeline_level1;
       //pipeline level 2 has to be started manually, to be able to prevent the pipeline 1 -> transition on end of ML
       pipeline_level3 <= pipeline_level2;
       pipeline_level4 <= pipeline_level3;
       pipeline_level5 <= pipeline_level4;
       pipeline_level6 <= pipeline_level5;
       pipeline_level7 <= pipeline_level6;
       pipeline_level8 <= pipeline_level7;  

       pipeline_level_ML2 <= pipeline_level_ML1;
       pipeline_level_ML3 <= pipeline_level_ML2;

       delay_signal_first_iteration_il_out <= delay_signal_first_iteration_il_in;
   end
       
   always @ (*)
     begin
		en_alu_addr   = 1'b0;
		en_alu_end    = 1'b0;
		en_alu_loop   = 1'b0;
		en_comp_alu   = 1'b0;
		en_reg_end_inner_loop = 1'b0;
		en_reg_len	 = 1'b0;
		en_reg_k      = 1'b0;
		en_reg_omega  = 1'b0;
		en_reg_t      = 1'b0;
		en_write_addr1= 1'b0;
		en_write_addr2= 1'b0;	
	    init_stagepow = 1'b0;
		mux_alu_addr  = 2'b00;
  		mux_alu_loop  = 2'b00;
  		mux_comp_alu_data=1'b0;
        mux_com_inner_loop_addr2 = 1'b0;
        mux_com_inner_loop_eil = 1'b0;
		mux_init_addr2 = 1'b0;
         mux_read_addr = 1'b0;
		mux_write_addr= 1'b0;
        	pipeline_level1= 1'b0;
        	pipeline_level2= 1'b0;
		pipeline_level_ML1=1'b0;
		delay_signal_first_iteration_il_in=1'b0;
		reset         = 1'b0;
		shift_stagepow= 1'b0;
 		sub_alu_end   = 1'b0;
 		ram_wr_en     = 1'b0;
 		ram_rd_en     = 1'b0;
         reset_omega   = 1'b0;
		reset_reg_k	= 1'b0;
		reset_reg_addr2= 1'b0;
		en_reg_jplus1 = 1'b0;
		en_reg_data1 = 1'b0;
		wr_data1_1 = 1'b0;
		wr_data1_2 = 1'b0;
		wr_data2_1 = 1'b0;
 		wr_data2_2 = 1'b0;
		flag_finished = 1'b0;


       // case statement
       case (state)
		
         SETUP   : begin
   // ready if FSM returns to idle state
					en_reg_len = 1'b1;
					init_stagepow = 1'b1;
					shift_stagepow = 1'b1;
					
					// manualy reset k addr2 and omega, since their reset needs to be done more often than normal reset
					//set omega to 1, this also requires en_reg_omega to be high, see datapath
         			reset_omega   = 1'b1;
					en_reg_omega  = 1'b1;
					//reset k
					reset_reg_k   = 1'b1;
					
					reset_reg_addr2 = 1'b1;

					//set end il to something other than 0 witout using additional hardware
					mux_alu_loop		=2'b00;
					en_alu_loop		=1'b1;
					en_reg_end_inner_loop = 1'b1;
					
                  end
         IL1  : begin
					//just start the pipeline
					pipeline_level1=1'b1;

					//ML1 and IL1 calculate the addr2 for the next IL iteration. in IL1 addr2 needs to be calculated from prev addr2, therefore mux = 1
       				mux_alu_addr = 2'b01;
			end
         IL2  : begin
					//pipeline stage 2 has to be manually started
					pipeline_level2=1'b1;
					//select the j+1 (next cycle addr2) calculated in the previous pipeline iteration as the new j (addr2 value)
					mux_init_addr2 = 2'b10;
					//save the freshly calcualted value for next cycles addr2 to the delay register
					en_reg_jplus1 = 1'b1;
                  end
         ML1  : begin
					//middle loop phase 1, also IL1, but first iterati

					//start pipeline
					pipeline_level1=1'b1;
					// calculate end of inner loop
					mux_alu_loop = 2'b01;
					en_alu_loop = 1'b1;
					
					//ML1 and IL1 calculate the addr2 for the next IL iteration. in ML1 addr2 needs to be calculated from k, therefore mux = 2
       				mux_alu_addr = 2'b10;
					
					
// BEGIN NOT ANYMORE
//					//calculate new k-index
//					mux_alu_loop = 2'b10;
//					en_alu_loop = 1'b1;
//					//save new k to register after calculation in step ML1
//					en_reg_k      = 1'b1;
// END NOT ANYMORE
				end
         ML2  : begin
					//middle loop phase 2
					//pipeline stage 2 has to be manually started
					pipeline_level2=1'b1;
					//save end_inner_loop
					//use alu loop output directly instead of old register value for inner loop end condition
					mux_com_inner_loop_eil = 1'b1;
					en_reg_end_inner_loop = 1'b1;
					// calculate next iterations k
					mux_alu_loop = 2'b10;
					en_alu_loop = 1'b1;
					//enable the register k save in the next cycle
					delay_signal_first_iteration_il_in = 1'b1;
					// set mux to directly use the value of k for addr2
					mux_init_addr2 = 2'b01;
					//save the freshly calcualted value for next cycles addr2 to the delay register
					en_reg_jplus1 = 1'b1;
	   				
                  end
         OL1  : begin
					// note: this will run, after an ML1 / IL1, whichs data can be invalidated, pipeline stage 2 will not be started.

					//setup params for this outerloop run (omega =1; stagepow right shift; calucalte delta omega; k=0)
					//reset k
					reset_reg_k   = 1'b1;
					
					//TODO; enable delta omega calculation
					
					//shift stagepow
					shift_stagepow =1'b1;
                  end
		HALT	 : begin
					flag_finished = !(pipeline_level1 ||pipeline_level2 ||pipeline_level3 ||pipeline_level4 ||pipeline_level5 ||pipeline_level6 ||pipeline_level7 ||pipeline_level8);
				end
       endcase
       // end of case statement

	
     if (pipeline_level1) begin
       //activate all parts for stage 1 of the pipeline
       //calculate addr2
       en_alu_addr = 1'b1;
		//note that mux selection is different for IL1 and ML1 and therefore its done there

     end
     if (pipeline_level2)begin
       //activate all parts for stage 2 of the pipeline


       //save addr2 into addr2 register
       en_write_addr2 = 1'b1;

       // since data is written to addr2 it wont be available in the reg when the cycle starts, so set IL Mux to directly use the output of the ALU
       mux_com_inner_loop_addr2 = 1'b1;
       //calculate addr1
       en_alu_addr = 1'b1;
       mux_alu_addr=2'b00;
     end
     if (pipeline_level3)begin
       //activate all parts for stage 3 of the pipeline
       //store the calculated addr1
       en_write_addr1 = 1'b1;
       //load data1
       mux_read_addr=1'b0;
       ram_rd_en = 1'b1;       
       //start Complex Multiplication for omega, because it calculates next iterations omega
       en_comp_alu = 1'b1;
       mux_comp_alu_data =1'b1;
     end
     if (pipeline_level4)begin
	   //activate all parts for stage 4 of the pipeline
       //load data2
       mux_read_addr=1'b1;
       ram_rd_en = 1'b1;
       //start comp mul on omega and data1
       en_comp_alu=1;
       mux_comp_alu_data=0;
	  // shift addr2 to next register, because it wil be overwritten
	  wr_data2_1 = 1'b1;
     end
     if (pipeline_level5)begin
		//activate all parts for stage 5 of the pipeline
       // delay data2 for one cycle, so that it can be used for the adders in the next two cycles
		en_reg_data1 = 1'b1;
       //store new omega to reg
       en_reg_omega = 1'b1;
	  // shift addr1 to next register, because it wil be overwritten
	  wr_data1_1 = 1'b1;
     end
     if (pipeline_level6)begin
       //activate all parts for stage 6 of the pipeline
       //store t 
       en_reg_t = 1;
       //calculate new data for addr2
       sub_alu_end=0;
       en_alu_end=1;
	  // shift addr2 to next register, because it wil be overwritten
	  wr_data2_2 = 1'b1;
     end
     if (pipeline_level7)begin
       //activate all parts for stage 7 of the pipeline
       //calculate new data for addr1
       sub_alu_end=1;
       en_alu_end=1;
       //save data to addr2
       mux_write_addr=1;
       ram_wr_en = 1'b1;
	  // shift addr1 to next register, because it wil be overwritten
	  wr_data1_2 = 1'b1;
     end
     if (pipeline_level8)begin
       //activate all parts for stage 8 of the pipeline
       //save data to addr1
       mux_write_addr=0;
       ram_wr_en = 1'b1;
     end
	 if(pipeline_level_ML2)begin
	 end
	 if(delay_signal_first_iteration_il_out)begin
		//this is basically ML3, but at the same time ML1 or IL1 could be running
	  	en_reg_k = 1'b1;
		// reset omega neds to happen here, because otherwise it will overwrite the previous iterations omega
		//set omega to 1, this also requires en_reg_omega to be high, see datapath
		reset_omega   = 1'b1;
		en_reg_omega  = 1'b1;
	 end
	end
    
endmodule
