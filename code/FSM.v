//Verilog HDL for "fc_example", "FFT_FSM2" "functional"


module FFT_FSM2 (comp_IL, comp_ML, comp_OL, clk, reset, load, state);

   parameter SETUP= 3'b000;
   parameter IL1  = 3'b001;
   parameter IL2  = 3'b010;
   parameter ML1  = 3'b011;
   parameter ML2  = 3'b100;
   parameter OL1  = 3'b101;
   parameter HALT = 3'b110;

   input clk;
   input reset;
   input comp_IL;
   input comp_ML;
   input comp_OL;
   input load;
   
   output [2:0] state;

   reg [2:0] state;
   reg [2:0] next_state;


   always @ (posedge clk or posedge reset)
     if (reset) begin
           state <= SETUP;
     end
     else begin
       state <= next_state;
     end
	always @(state or comp_IL or comp_ML or comp_OL or load)
		case(state)
			HALT	:if(load) begin
					next_state=SETUP;
				end
				else begin
					next_state = HALT;
				end
			SETUP: 	next_state=ML1; // ML1 is IL1 with modifications, for the first IL iteration
			IL1	:  if (comp_ML)begin
						next_state = IL2; // this used to be OL1, if working just remove if and only put IL2 as next state
					end
				else begin
					next_state = IL2;
				end
			IL2: if (!comp_IL)begin
						next_state = IL1;
					end
				else begin
					next_state = ML1;
				end
			ML1: if (comp_ML)begin
						next_state = OL1;
					end
				else begin
					next_state = ML2;
				end
			ML2: if (!comp_IL)begin
						next_state = IL1;
					end
				else begin
					next_state = ML1;
				end
			OL1: if(comp_OL) begin // we do this later
					next_state = HALT;
				  end
				  else begin
					next_state = ML1;
				  end
        		default: next_state = HALT;
		endcase
endmodule 	

