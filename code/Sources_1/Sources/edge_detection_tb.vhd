LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY EdgeDetector_tb IS
END EdgeDetector_tb;
 
ARCHITECTURE behavior OF EdgeDetector_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT EdgeDetector
    PORT(
         Clk : IN  std_logic;
         InputSignal : IN  std_logic;
         Edge : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal Clk : std_logic := '0';
   signal Input : std_logic := '0';
	
 	--Outputs
   signal Output : std_logic;

   -- Clock period definitions
   constant clk_period : time := 20 ns;	-- 50MHz
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: EdgeDetector PORT MAP (
          Clk => Clk,
          InputSignal => Input,
          Edge => Output
        );

   -- Clock process definitions
   clk_process :process
   begin
		Clk <= '1';
		wait for clk_period/2;
		Clk <= '0';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
   
        Input <= '0';
        wait for 200 ns;        
        Input <= '1';
        wait for 200 ns;
        Input <= '0';	
        wait for 200 ns;        
        Input <= '1';
        wait for 200 ns;
        Input <= '0';    
        wait;
      
   end process;
END;