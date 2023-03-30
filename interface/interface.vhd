
library ieee;
  use ieee.std_logic_1164.all;

package interface is

  component uart_txrx is
    generic (
      clk_freq   : integer   := 100_000_000;
      baudrate   : integer   := 115200;
      osrate     : integer   := 16;
      dwidth     : integer   := 8;
      parity     : integer   := 0;
      paritytype : std_logic := '0'
    );
    port (
      clk      : in    std_logic;
      aresetn  : in    std_logic;
      txenable : in    std_logic;
      txdata   : in    std_logic_vector(dwidth - 1 downto 0);
      txbusy   : out   std_logic;
      rxbusy   : out   std_logic;
      rxerror  : out   std_logic;
      rxdata   : out   std_logic_vector(dwidth - 1 downto 0);

      tx : out   std_logic;
      rx : in    std_logic
    );
  end component;

  component uart_tx is
    generic (
      clk_freq   : integer   := 100_000_000;
      baudrate   : integer   := 115200;
      osrate     : integer   := 16;
      dwidth     : integer   := 8;
      parity     : integer   := 0;
      paritytype : std_logic := '0'
    );
    port (
      clk      : in    std_logic;
      aresetn  : in    std_logic;
      txenable : in    std_logic;
      txdata   : in    std_logic_vector(dwidth - 1 downto 0);
      txbusy   : out   std_logic;

      tx : out   std_logic
    );
  end component;

  component uart_rx is
    generic (
      clk_freq   : integer   := 100_000_000;
      baudrate   : integer   := 115200;
      osrate     : integer   := 16;
      dwidth     : integer   := 8;
      parity     : integer   := 0;
      paritytype : std_logic := '0'
    );
    port (
      clk     : in    std_logic;
      aresetn : in    std_logic;
      rxbusy  : out   std_logic;
      rxerror : out   std_logic;
      rxdata  : out   std_logic_vector(dwidth - 1 downto 0);
      rx      : in    std_logic
    );
  end component;

end package interface;
