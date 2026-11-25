library ieee;
use ieee.std_logic_1164.all;

entity flipflop is
    port(clk, rst : in  std_logic;           
         enable   : in  std_logic;
         input    : in  std_logic;
         output   : out std_logic);
end flipflop;

architecture behavioral of flipflop is
begin
    process (clk)
    begin
        if (clk'event and clk='1') then
            output <= input;
        end if;
    end process;


--process(clk)
--begin
--    if (clk'event and clk='1') then
--        if (rst = '0') then
--            output <= input;
--        else
--            output <= '0';
--        end if;
--    end if;
--end process;

--process(clk,rst)
--begin
--    if (rst = '0') then 
--        if (clk'event and clk='1') then
--            output <= input;
--        end if;
--    else
--        output <= '0';
--    end if;
--end process;



--process(clk,rst)
--begin
--    if(rst = '0') then 
--        if (clk'event and clk='1') then
--            if (enable = '1') then
--                output <= input;
--            end if;
--        end if;
--    else
--        output <= '0';
--    end if;
--end process;

end behavioral;