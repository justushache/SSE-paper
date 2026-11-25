library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity counters_tb is
end counters_tb;

architecture Behavioral of counters_tb is
    constant n : positive := 4;

    -- Component Declaration for the Unit Under Test (UUT)
    component up_dn_counter_top
        generic (
            n : positive := 4
        );
        port (  
            CLK : in  STD_LOGIC;
            updown, clr, ld, en : in STD_LOGIC;
            D : in STD_LOGIC_VECTOR(n-1 downto 0);
            Q : out  STD_LOGIC_VECTOR (n-1 downto 0);
            ovrflow : out  STD_LOGIC
        ); 
    end component;

    -- Inputs
    signal Clk : STD_LOGIC := '0';
    signal Clear : STD_LOGIC := '0';
    signal UpDown : STD_LOGIC := '0';
    signal Enable : STD_LOGIC := '0';
    signal Load : STD_LOGIC := '0';
    signal D : STD_LOGIC_VECTOR (n-1 downto 0) := (others=>'0');

    -- Outputs
    signal Ovrflow : STD_LOGIC := '0';
    signal Q : STD_LOGIC_VECTOR (n-1 downto 0) := (others=>'0');

    -- Clock period definitions
    constant clk_period : time := 10 ns;    -- 100MHz (PIN Y9 on the Zedboard)
    
begin
    -- Instantiate the Unit Under Test (UUT)
    uut: up_dn_counter_top
        generic map (
            n => n
        )
        port map (
            CLK => Clk,
            updown => UpDown,
            clr => Clear,
            ld => Load,
            en => Enable,
            D => D,
            Q => Q,
            ovrflow => Ovrflow
        );

    -- Clock process definitions
    clk_process : process
    begin
        Clk <= '1';
        wait for clk_period/2;
        Clk <= '0';
        wait for clk_period/2;
    end process;

    stim_proc: process
    begin
        wait for 2 * clk_period;
        Clear <= '1';
    
        wait for clk_period;
        Clear <= '0';
        wait for clk_period*3;
        
        Enable <= '1';
        
        -- Test upward counting
        UpDown <= '1';
        Load <= '1';
        D <= "0010"; -- Load a value into the counter
        wait for clk_period;
        Load <= '0';
        Enable <= '1';
        wait for 5 * clk_period; -- Wait for a few cycles to observe the counting
    
        -- Test downward counting
        UpDown <= '0';
        Load <= '1';
        D <= "1101"; -- Load a value into the counter
        wait for clk_period;
        Load <= '0';
        Enable <= '1';
        wait for 5 * clk_period; -- Wait for a few cycles to observe the counting
    
        -- Test overflow +
        UpDown <= '1'; -- Set to upward counting
        Load <= '1';
        D <= "1100"; -- Load a value close to the maximum
        wait for clk_period;
        Load <= '0';
        wait for 10 * clk_period; -- Wait for a few cycles to observe the counting and overflow
        
        -- Test overflow -
        UpDown <= '0'; -- Set to upward counting
        Load <= '1';
        D <= "0011"; -- Load a value close to the maximum
        wait for clk_period;
        Load <= '0';
        wait for 10 * clk_period; -- Wait for a few cycles to observe the counting and overflow
        
        Enable <= '0';
        wait;
    end process;
    
end Behavioral;
