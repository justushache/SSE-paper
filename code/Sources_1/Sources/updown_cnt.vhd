library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.ALL;

entity up_dn_counter_top is
    Generic(n : positive := 4
    );
    Port ( CLK : in  STD_LOGIC;     -- input clock
           -- input
           updown, clr, ld, en : in STD_LOGIC; -- inputs 
           D : in STD_LOGIC_VECTOR(n-1 downto 0); -- seting input
           -- outputs
           Q : out  STD_LOGIC_VECTOR (n-1 downto 0); -- counter
           ovrflow : out  STD_LOGIC);    -- OVERFLOW
end up_dn_counter_top;


architecture Behavioral of up_dn_counter_top is

    signal ones : unsigned(n-1 downto 0) := (others=>'1');
    signal zero : unsigned(n-1 downto 0) := (others=>'0');

begin
    
    -- up/down counter
    process (CLK)
        variable count : unsigned(n-1 downto 0) := (others=>'0');
        variable of_var : STD_LOGIC := '0';
    begin
        if rising_edge(CLK) then
            if (clr = '1') then
                count := zero;   -- clear
                of_var := '0';
            elsif (en = '0') then
                  
				  
            elsif (en = '1') then
                if (ld = '1') then
                    
					
                else
                    if (updown = '0') then
                        if (count = zero) then
                           
						   
						   
                        else
                          
						  
						  
                        end if;
                    else
                        if (count = ones) then
                           
						   
						   
                        else
                           
						   
						   
                        end if;
                    end if;
                end if;
            else
                count := count;   -- maintain counter
            end if;
        end if;

        Q <= std_logic_vector(count);
        ovrflow <= of_var;
    end process;
        
end Behavioral;