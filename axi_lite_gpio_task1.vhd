library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axi_lite_gpio_task1 is
    Generic (
        C_S_AXI_ADDR_WIDTH : integer := 4;
        C_S_AXI_DATA_WIDTH : integer := 32
    );
    Port (
        S_AXI_ACLK    : in  STD_LOGIC;
        S_AXI_ARESETN : in  STD_LOGIC;
        -- AXI Write Channel
        S_AXI_AWADDR  : in  STD_LOGIC_VECTOR(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_AWVALID : in  STD_LOGIC;
        S_AXI_AWREADY : out STD_LOGIC;
        S_AXI_WDATA   : in  STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_WVALID  : in  STD_LOGIC;
        S_AXI_WREADY  : out STD_LOGIC;
        S_AXI_BRESP   : out STD_LOGIC_VECTOR(1 downto 0);
        S_AXI_BVALID  : out STD_LOGIC;
        S_AXI_BREADY  : in  STD_LOGIC;
        -- AXI Read Channel
        S_AXI_ARADDR  : in  STD_LOGIC_VECTOR(C_S_AXI_ADDR_WIDTH-1 downto 0);
        S_AXI_ARVALID : in  STD_LOGIC;
        S_AXI_ARREADY : out STD_LOGIC;
        S_AXI_RDATA   : out STD_LOGIC_VECTOR(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_RRESP   : out STD_LOGIC_VECTOR(1 downto 0);
        S_AXI_RVALID  : out STD_LOGIC;
        S_AXI_RREADY  : in  STD_LOGIC;
        -- Custom I/O (LED & Switch)
        gpio_out      : out STD_LOGIC_VECTOR(15 downto 0);
        sw_in         : in  STD_LOGIC_VECTOR(15 downto 0)
    );
end axi_lite_gpio_task1;

architecture Behavioral of axi_lite_gpio_task1 is
    signal loc_addr : STD_LOGIC_VECTOR(1 downto 0);
    signal reg0, reg2, reg3 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal reg1 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    
    signal awready_reg, wready_reg, bvalid_reg : STD_LOGIC := '0';
    signal arready_reg, rvalid_reg : STD_LOGIC := '0';
    signal rdata_reg : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
begin
    loc_addr <= S_AXI_AWADDR(3 downto 2) when (S_AXI_AWVALID = '1') else S_AXI_ARADDR(3 downto 2);

    S_AXI_AWREADY <= awready_reg;
    S_AXI_WREADY  <= wready_reg;
    S_AXI_BVALID  <= bvalid_reg;
    S_AXI_BRESP   <= "00";
    S_AXI_ARREADY <= arready_reg;
    S_AXI_RVALID  <= rvalid_reg;
    S_AXI_RRESP   <= "00";
    S_AXI_RDATA   <= rdata_reg;

    -- Update reg1 secara langsung dari nilai switch fisik (sw_in)
    reg1(15 downto 0)  <= sw_in;
    reg1(31 downto 16) <= (others => '0');

    -- Proses Tulis AXI-Lite (Reg0 untuk Output LED)
    process(S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                awready_reg <= '0';
                wready_reg  <= '0';
                bvalid_reg  <= '0';
                reg0 <= (others => '0');
                reg2 <= (others => '0');
                reg3 <= (others => '0');
            else
                if (awready_reg = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1') then
                    awready_reg <= '1';
                    wready_reg  <= '1';
                    bvalid_reg  <= '1';
                    case loc_addr is
                        when "00"   => reg0 <= S_AXI_WDATA;
                        -- Alamat "01" (reg1) bersifat Read-Only untuk membaca switch
                        when "10"   => reg2 <= S_AXI_WDATA;
                        when "11"   => reg3 <= S_AXI_WDATA;
                        when others => null;
                    end case;
                elsif (bvalid_reg = '1' and S_AXI_BREADY = '1') then
                    bvalid_reg  <= '0';
                    awready_reg <= '0';
                    wready_reg  <= '0';
                else
                    awready_reg <= '0';
                    wready_reg  <= '0';
                end if;
            end if;
        end if;
    end process;

    -- Proses Baca AXI-Lite (Bisa membaca Reg0 maupun Reg1 Status Switch)
    process(S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                arready_reg <= '0';
                rvalid_reg  <= '0';
                rdata_reg   <= (others => '0');
            else
                if (arready_reg = '0' and S_AXI_ARVALID = '1') then
                    arready_reg <= '1';
                    rvalid_reg  <= '1';
                    case loc_addr is
                        when "00"   => rdata_reg <= reg0;
                        when "01"   => rdata_reg <= reg1; -- Membaca status switch
                        when "10"   => rdata_reg <= reg2;
                        when "11"   => rdata_reg <= reg3;
                        when others => rdata_reg <= (others => '0');
                    end case;
                elsif (rvalid_reg = '1' and S_AXI_RREADY = '1') then
                    rvalid_reg  <= '0';
                    arready_reg <= '0';
                else
                    arready_reg <= '0';
                end if;
            end if;
        end if;
    end process;

    gpio_out <= reg0(15 downto 0);
end Behavioral;