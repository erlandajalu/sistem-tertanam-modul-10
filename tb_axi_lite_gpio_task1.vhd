library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_axi_lite_gpio_task1 is
end tb_axi_lite_gpio_task1;

architecture sim of tb_axi_lite_gpio_task1 is
    signal clk : std_logic := '0';
    signal rst_n : std_logic := '0';
    
    signal awaddr : std_logic_vector(3 downto 0) := (others => '0');
    signal awvalid : std_logic := '0';
    signal awready : std_logic;
    signal wdata : std_logic_vector(31 downto 0) := (others => '0');
    signal wvalid : std_logic := '0';
    signal wready : std_logic;
    signal bresp : std_logic_vector(1 downto 0);
    signal bvalid : std_logic;
    signal bready : std_logic := '0';
    
    signal araddr : std_logic_vector(3 downto 0) := (others => '0');
    signal arvalid : std_logic := '0';
    signal arready : std_logic;
    signal rdata : std_logic_vector(31 downto 0);
    signal rresp : std_logic_vector(1 downto 0);
    signal rvalid : std_logic;
    signal rready : std_logic := '0';
    
    signal gpio_out : std_logic_vector(15 downto 0);
    signal sw_in : std_logic_vector(15 downto 0) := (others => '0');
    
    constant CLK_PERIOD : time := 10 ns;
begin
    uut: entity work.axi_lite_gpio_task1
        port map (
            S_AXI_ACLK => clk, S_AXI_ARESETN => rst_n,
            S_AXI_AWADDR => awaddr, S_AXI_AWVALID => awvalid, S_AXI_AWREADY => awready,
            S_AXI_WDATA => wdata, S_AXI_WVALID => wvalid, S_AXI_WREADY => wready,
            S_AXI_BRESP => bresp, S_AXI_BVALID => bvalid, S_AXI_BREADY => bready,
            S_AXI_ARADDR => araddr, S_AXI_ARVALID => arvalid, S_AXI_ARREADY => arready,
            S_AXI_RDATA => rdata, S_AXI_RRESP => rresp, S_AXI_RVALID => rvalid, S_AXI_RREADY => rready,
            gpio_out => gpio_out, sw_in => sw_in
        );

    clk_process : process
    begin
        clk <= '0'; wait for CLK_PERIOD/2;
        clk <= '1'; wait for CLK_PERIOD/2;
    end process;

    stim_process : process
    begin
        rst_n <= '0';
        sw_in <= x"3F0A"; -- Berikan nilai awal pada switch simulasi
        wait for 30 ns;
        rst_n <= '1';
        wait for 20 ns;

        -- 1. Uji Tulis LED (Reg 0 / Alamat 0x0)
        awaddr  <= "0000";
        awvalid <= '1';
        wdata   <= x"00001234";
        wvalid  <= '1';
        bready  <= '1';
        wait for CLK_PERIOD;
        awvalid <= '0';
        wvalid  <= '0';
        wait for 30 ns;

        -- 2. Uji Baca Status Switch dari Register 1 (Alamat 0x4)
        araddr  <= "0100"; -- Alamat untuk reg1 (offset 4)
        arvalid <= '1';
        rready  <= '1';
        wait for CLK_PERIOD;
        arvalid <= '0';
        wait for 40 ns;

        wait;
    end process;
end sim;