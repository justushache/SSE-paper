library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity EdgeDetector is
    Port ( Clk : in STD_LOGIC;
           InputSignal : in STD_LOGIC;
           Edge : out STD_LOGIC);
end EdgeDetector;

architecture Behavioral of EdgeDetector is

    signal delay_bounce_0 : STD_LOGIC;
    signal delay_bounce_1 : STD_LOGIC;   
     
begin

    sync_and_edge_detection_debounced : process(clk)	-- Detects rising and falling edge.
            begin
            if(rising_edge(clk)) then
             --   delay_bounce_0 <= ....;
             --   .... <= InputSignal;
            end if;
        end process;
        -- Edge <= (not ....) and ....;

end Behavioral;