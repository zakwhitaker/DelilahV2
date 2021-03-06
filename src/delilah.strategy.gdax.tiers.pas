unit delilah.strategy.gdax.tiers;

{$mode delphi}

interface

uses
  Classes, SysUtils, delilah.strategy.channels, delilah.types,
  delilah.strategy.gdax, fgl, delilah.strategy,
  delilah.ticker.gdax;

type

  (*
    enum showing all available order positions taken at a particular tier
  *)
  TPositionSize = (
    psSmall,
    psMid,
    psLarge,
    psGTFO
  );

  ITierStrategyGDAX = interface;
  PTierStrategyGDAX = ^ITierStrategyGDAX;

  { TActiveCriteriaDetails }
  (*
    details of a current feed operation provided to the active callback
    callback methods
  *)
  TActiveCriteriaDetails = record
  public
    type
      PTicker = ^ITicker;
  private
    FAAC: Extended;
    FData: Pointer;
    FFunds: Extended;
    FInv: Extended;
    FIsBuy: Boolean;
    FTotal: Extended;
    FStrat: PTierStrategyGDAX;
    FTick: PTicker;
  public
    property TotalFunds : Extended read FTotal write FTotal;
    property Funds : Extended read FFunds write FFunds;
    property Inventory : Extended read FInv write FInv;
    property AAC : Extended read FAAC write FAAC;
    property IsBuy : Boolean read FIsBuy write FIsBuy;
    property Ticker : PTicker read FTick write FTick;
    property Strategy : PTierStrategyGDAX read FStrat write FStrat;
    property Data : Pointer read FData write FData;
  end;

  PActiveCriteriaDetails = ^TActiveCriteriaDetails;

  TActiveCriteriaCallback = procedure(Const ADetails : PActiveCriteriaDetails;
    Var Active : Boolean);

  TActiveCriteriaCallbackArray = array of TActiveCriteriaCallback;

  { ITierStrategyGDAX }
  (*
    strategy which sets various channels above and below each other (tiered)
    in order to open and close different sized positions
  *)
  ITierStrategyGDAX = interface(IStrategyGDAX)
    ['{C9AA33EF-DB73-4790-BD48-5AB5E27A4A81}']
    //property methods
    function GetActiveCriteria: TActiveCriteriaCallbackArray;
    function GetActiveCriteriaData: Pointer;
    function GetAvoidChop: Boolean;
    function GetChannel: IChannelStrategy;
    function GetFixedProfit: Boolean;
    function GetGTFOPerc: Single;
    function GetIgnoreProfit: Single;
    function GetLargePerc: Single;
    function GetLargeSellPerc: Single;
    function GetLimitFee: Single;
    function GetMarketFee: Single;
    function GetMaxScaleBuy: Single;
    function GetMidPerc: Single;
    function GetMidSellPerc: Single;
    function GetMinProfit: Single;
    function GetMinReduction: Single;
    function GetOnlyLower: Boolean;
    function GetOnlyProfit: Boolean;
    function GetSmallPerc: Single;
    function GetSmallSellPerc: Single;
    function GetUseMarketBuy: Boolean;
    function GetUseMarketSell: Boolean;
    procedure SetActiveCritera(Const AValue: TActiveCriteriaCallbackArray);
    procedure SetActiveCriteriaData(Const AValue: Pointer);
    procedure SetAvoidChop(Const AValue: Boolean);
    procedure SetFixedProfit(const AValue: Boolean);
    procedure SetGTFOPerc(Const AValue: Single);
    procedure SetIgnoreProfit(Const AValue: Single);
    procedure SetLargePerc(Const AValue: Single);
    procedure SetLargeSellPerc(Const AValue: Single);
    procedure SetLimitFee(Const AValue: Single);
    procedure SetMarketFee(Const AValue: Single);
    procedure SetMarketSell(Const AValue: Boolean);
    procedure SetMaxScaleBuy(const AValue: Single);
    procedure SetMidPerc(Const AValue: Single);
    procedure SetMidSellPerc(Const AValue: Single);
    procedure SetMinProfit(Const AValue: Single);
    procedure SetMinReduction(Const AValue: Single);
    procedure SetOnlyLower(Const AValue: Boolean);
    procedure SetOnlyProfit(Const AValue: Boolean);
    procedure SetSmallPerc(Const AValue: Single);
    procedure SetSmallSellPerc(Const AValue: Single);
    procedure SetUseMarketBuy(Const AValue: Boolean);

    //properties
    (*
      specific details about all channels used can be accessed from this
      property, and changed if required
    *)
    property ChannelStrategy : IChannelStrategy read GetChannel;
    (*
      when true, sell orders can only be placed if it would result in profit
    *)
    property OnlyProfit : Boolean read GetOnlyProfit write SetOnlyProfit;

    (*
      when only profit is true, and so is fixed profit, dynamic selling
      points are ignored, and a "fixed" sell will occur when the profit
      threshold is reached
    *)
    property FixedProfit : Boolean read GetFixedProfit write SetFixedProfit;

    (*
      when inventory makes up a certain "threshold" percentage compared
      to funds available, a sell is allowed. If this setting is not desired
      set to 0 or something greater than 1.0 (100%)
    *)
    property IgnoreOnlyProfitThreshold : Single read GetIgnoreProfit write SetIgnoreProfit;
    (*
      minimum percentage to sell inventory for, only works with OnlyProfit true
    *)
    property MinProfit : Single read GetMinProfit write SetMinProfit;
    (*
      when true, buy orders can only be placed if it would lower AAC
    *)
    property OnlyLowerAAC : Boolean read GetOnlyLower write SetOnlyLower;
    (*
      minimum percentage to reduce AAC, only works when OnlyLowerAAC is True
    *)
    property MinReduction : Single read GetMinReduction write SetMinReduction;
    (*
      when true, market orders are made for buys instead of limit orders ensuring
      a quick entry price, but most likely incurring fees
    *)
    property UseMarketBuy : Boolean read GetUseMarketBuy write SetUseMarketBuy;
    (*
      when true, market orders are made for sells instead of limit orders ensuring
      a quick exit price, but most likely incurring fees
    *)
    property UseMarketSell : Boolean read GetUseMarketSell write SetMarketSell;
    (*
      using a combination of order fee and min profit, will look at the anchor
      and deviations to try and avoid purchasing inventory in choppy conditions.
      this should avoid loading up on bags during uncertain times
    *)
    property AvoidChop : Boolean read GetAvoidChop write SetAvoidChop;
    (*
      the market fee associated with market orders. this setting is used
      in conjunction with OnlyProfit to determine if a sell can be made
    *)
    property MarketFee : Single read GetMarketFee write SetMarketFee;
    (*
      the fee associated with limit fee (works like marketfee)
    *)
    property LimitFee : Single read GetLimitFee write SetLimitFee;
    (*
      percentage of funds/inventory to use when a small tier position is detected buying
    *)
    property SmallTierPerc : Single read GetSmallPerc write SetSmallPerc;
    (*
      percentage of funds/inventory to use when a medium tier position is detected buying
    *)
    property MidTierPerc : Single read GetMidPerc write SetMidPerc;
    (*
      percentage of funds/inventory to use when a large tier position is detected buying
    *)
    property LargeTierPerc : Single read GetLargePerc write SetLargePerc;
    (*
      percentage of funds/inventory to use when a small tier position is detected selling
    *)
    property SmallTierSellPerc : Single read GetSmallSellPerc write SetSmallSellPerc;
    (*
      percentage of funds/inventory to use when a medium tier position is detected selling
    *)
    property MidTierSellPerc : Single read GetMidSellPerc write SetMidSellPerc;
    (*
      percentage of funds/inventory to use when a large tier position is detected selling
    *)
    property LargeTierSellPerc : Single read GetLargeSellPerc write SetLargeSellPerc;
    (*
      when GTFO signal is reached, determines the percentage of inventory to sell
    *)
    property GTFOPerc : Single read GetGTFOPerc write SetGTFOPerc;

    (*
      active criteria callbacks can be used to add in custom pre-processing
      rules for feed data, that report back to to the strategy whether an
      action should be performed
    *)
    property ActiveCriteria : TActiveCriteriaCallbackArray read GetActiveCriteria write SetActiveCritera;
    property ActiveCriteriaData : Pointer read GetActiveCriteriaData write SetActiveCriteriaData;

    (*
      when set to anything non-zero, will scale buys proportionally to
      the amount of remaining funds, all the way up to this "max" percentage
    *)
    property MaxScaledBuyPerc : Single read GetMaxScaleBuy write SetMaxScaleBuy;
  end;

  { TTierStrategyGDAXImpl }
  (*
    base implementation of a GDAX tiered stragegy
  *)
  TTierStrategyGDAXImpl = class(TStrategyGDAXImpl,ITierStrategyGDAX)
  strict private
    FChannel: IChannelStrategy;
    FOnlyLower,
    FOnlyProfit,
    FUseMarketBuy,
    FUseMarketSell: Boolean;
    FSmallPerc,
    FMidPerc,
    FMarketFee,
    FLimitFee,
    FLargePerc,
    FSmallSellPerc,
    FMidSellPerc,
    FLargeSellPerc,
    FMinProfit,
    FMinReduction,
    FGTFOPerc,
    FIgnoreProfitPerc,
    FMaxScaleBuy: Single;
    FDontBuy,
    FSellItAllNow,
    FLargeBuy,
    FSmallBuy,
    FLargeSell,
    FMidSell,
    FSmallSell,
    FAvoidChop,
    FFixed: Boolean;
    FIDS: TFPGList<String>;
    FActiveCriteria: TActiveCriteriaCallbackArray;
    FActiveCriteriaData: Pointer;
  private
    function GetActiveCriteria: TActiveCriteriaCallbackArray;
    function GetActiveCriteriaData: Pointer;
    function GetChannel: IChannelStrategy;
    function GetLargePerc: Single;
    function GetLargeSellPerc: Single;
    function GetMarketFee: Single;
    function GetLimitFee: Single;
    function GetMaxScaleBuy: Single;
    function GetMidPerc: Single;
    function GetMidSellPerc: Single;
    function GetMinProfit: Single;
    function GetMinReduction: Single;
    function GetOnlyLower: Boolean;
    function GetOnlyProfit: Boolean;
    function GetSmallPerc: Single;
    function GetSmallSellPerc: Single;
    function GetUseMarketBuy: Boolean;
    function GetUseMarketSell: Boolean;
    function GetGTFOPerc: Single;
    function GetIgnoreProfit: Single;
    procedure SetActiveCritera(Const AValue: TActiveCriteriaCallbackArray);
    procedure SetActiveCriteriaData(Const AValue: Pointer);
    procedure SetLargePerc(Const AValue: Single);
    procedure SetLargeSellPerc(Const AValue: Single);
    procedure SetMarketFee(Const AValue: Single);
    procedure SetLimitFee(Const AValue: Single);
    procedure SetMarketSell(Const AValue: Boolean);
    procedure SetMidPerc(Const AValue: Single);
    procedure SetMidSellPerc(Const AValue: Single);
    procedure SetMinProfit(Const AValue: Single);
    procedure SetMinReduction(Const AValue: Single);
    procedure SetOnlyLower(Const AValue: Boolean);
    procedure SetOnlyProfit(Const AValue: Boolean);
    procedure SetSmallPerc(Const AValue: Single);
    procedure SetSmallSellPerc(Const AValue: Single);
    procedure SetUseMarketBuy(Const AValue: Boolean);
    procedure SetGTFOPerc(Const AValue: Single);
    procedure SetIgnoreProfit(Const AValue: Single);
    procedure InitChannel;
    procedure GTFOUp(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure GTFOLow(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure LargeBuyUp(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure LargeBuyLow(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure SmallBuyUp(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure SmallBuyLow(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure SmallSellUp(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure SmallSellLow(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure LargeSellUp(Const ASender:IChannel;Const ADirection:TChannelDirection);
    procedure LargeSellLow(Const ASender:IChannel;Const ADirection:TChannelDirection);
    function GetAvoidChop: Boolean;
    procedure SetAvoidChop(const AValue: Boolean);
    procedure SetMaxScaleBuy(const AValue: Single);
    function GetFixedProfit: Boolean;
    procedure SetFixedProfit(const AValue: Boolean);
  strict private

    (*
      provided some details about the account and market, this will calculate
      the scaled buy percentage
    *)
    function CalculateScaleBuyPercent(const AFunds, AInventory,
      AAAC : Extended; const ABuyPerc : Single) : Single;
  strict protected
    const
      GTFO = 'gtfo';
      LARGE_BUY = 'large-buy';
      SMALL_BUY = 'small-buy';
      SMALL_SELL = 'small-sell';
      LARGE_SELL = 'large-sell';
  strict protected
    function DoFeed(const ATicker: ITicker; const AManager: IOrderManager;
      const AFunds, AInventory, AAAC: Extended; out Error: String): Boolean;override;
    (*
      returns true if we should take a particular position
    *)
    function GetPosition(Const AInventory:Extended;Out Size:TPositionSize;Out Percentage:Single;Out Sell:Boolean):Boolean;
    function GetFixedSellPosition(Const AInventory:Extended; const AAAC : Extended; const ATicker : ITickerGDAX; Out Size:TPositionSize; Out Percentage:Single; Out Sell : Boolean):Boolean;
    (*
      after a call is made to GetPosition, call this method to report that
      we were successful placing to the order manager
    *)
    procedure PositionSuccess;
    (*
      clears managed positions by cancelling those not completed
    *)
    procedure ClearOldPositions(Const AManager:IOrderManager);
    function ChoppyWaters : Boolean;
    function ActiveCriteriaCheck(Const ADetails : PActiveCriteriaDetails) : Boolean;
  public

    property ChannelStrategy : IChannelStrategy read GetChannel;
    property OnlyProfit : Boolean read GetOnlyProfit write SetOnlyProfit;
    property FixedProfit : Boolean read GetFixedProfit write SetFixedProfit;
    property IgnoreOnlyProfitThreshold : Single read GetIgnoreProfit write SetIgnoreProfit;
    property MinProfit : Single read GetMinProfit write SetMinProfit;
    property OnlyLowerAAC : Boolean read GetOnlyLower write SetOnlyLower;
    property MinReduction : Single read GetMinReduction write SetMinReduction;
    property UseMarketBuy : Boolean read GetUseMarketBuy write SetUseMarketBuy;
    property UseMarketSell : Boolean read GetUseMarketSell write SetMarketSell;
    property AvoidChop : Boolean read GetAvoidChop write SetAvoidChop;
    property MarketFee : Single read GetMarketFee write SetMarketFee;
    property LimitFee : Single read GetLimitFee write SetLimitFee;
    property SmallTierPer : Single read GetSmallPerc write SetSmallPerc;
    property MidTierPerc : Single read GetMidPerc write SetMidPerc;
    property LargeTierPerc : Single read GetLargePerc write SetLargePerc;
    property SmallTierSellPerc : Single read GetSmallSellPerc write SetSmallSellPerc;
    property MidTierSellPerc : Single read GetMidSellPerc write SetMidSellPerc;
    property LargeTierSellPerc : Single read GetLargeSellPerc write SetLargeSellPerc;
    property GTFOPerc : Single read GetGTFOPerc write SetGTFOPerc;
    property ActiveCriteria : TActiveCriteriaCallbackArray read GetActiveCriteria write SetActiveCritera;
    property ActiveCriteriaData : Pointer read GetActiveCriteriaData write SetActiveCriteriaData;
    property MaxScaledBuyPerc : Single read GetMaxScaleBuy write SetMaxScaleBuy;
    constructor Create(const AOnInfo, AOnError, AOnWarn: TStrategyLogEvent);override;
    destructor Destroy; override;
  end;

implementation
uses
  math,
  gdax.api.consts,
  gdax.api.types,
  gdax.api.orders,
  delilah.order.gdax;

{ TTierStrategyGDAXImpl }

function TTierStrategyGDAXImpl.GetChannel: IChannelStrategy;
begin
  Result:=FChannel;
end;

function TTierStrategyGDAXImpl.GetActiveCriteria: TActiveCriteriaCallbackArray;
begin
  Result:=FActiveCriteria;
end;

function TTierStrategyGDAXImpl.GetActiveCriteriaData: Pointer;
begin
  Result:=FActiveCriteriaData;
end;

function TTierStrategyGDAXImpl.GetLargePerc: Single;
begin
  Result:=FLargePerc;
end;

function TTierStrategyGDAXImpl.GetLargeSellPerc: Single;
begin
  Result:=FLargeSellPerc;
end;

function TTierStrategyGDAXImpl.GetMarketFee: Single;
begin
  Result:=FMarketFee;
end;

function TTierStrategyGDAXImpl.GetLimitFee: Single;
begin
  Result:=FLimitFee;
end;

function TTierStrategyGDAXImpl.GetMaxScaleBuy: Single;
begin
  Result := FMaxScaleBuy;
end;

function TTierStrategyGDAXImpl.GetMidPerc: Single;
begin
  Result:=FMidPerc;
end;

function TTierStrategyGDAXImpl.GetMidSellPerc: Single;
begin
  Result:=FMidSellPerc;
end;

function TTierStrategyGDAXImpl.GetMinProfit: Single;
begin
  Result:=FMinProfit;
end;

function TTierStrategyGDAXImpl.GetMinReduction: Single;
begin
  Result:=FMinReduction;
end;

function TTierStrategyGDAXImpl.GetOnlyLower: Boolean;
begin
  Result:=FOnlyLower;
end;

function TTierStrategyGDAXImpl.GetOnlyProfit: Boolean;
begin
  Result:=FOnlyProfit;
end;

function TTierStrategyGDAXImpl.GetSmallPerc: Single;
begin
  Result:=FSmallPerc;
end;

function TTierStrategyGDAXImpl.GetSmallSellPerc: Single;
begin
  Result:=FSmallSellPerc;
end;

function TTierStrategyGDAXImpl.GetUseMarketBuy: Boolean;
begin
  Result:=FUseMarketBuy;
end;

function TTierStrategyGDAXImpl.GetUseMarketSell: Boolean;
begin
  Result:=FUseMarketSell;
end;

function TTierStrategyGDAXImpl.GetGTFOPerc: Single;
begin
  Result:=FGTFOPerc;
end;

function TTierStrategyGDAXImpl.GetIgnoreProfit: Single;
begin
  Result:=FIgnoreProfitPerc;
end;

procedure TTierStrategyGDAXImpl.SetActiveCritera(
  const AValue: TActiveCriteriaCallbackArray);
begin
  FActiveCriteria:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetActiveCriteriaData(const AValue: Pointer);
begin
  FActiveCriteriaData:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetLargePerc(const AValue: Single);
begin
  if AValue<0 then
    FLargePerc:=0
  else
    FLargePerc:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetLargeSellPerc(const AValue: Single);
begin
  FLargeSellPerc:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetMarketFee(const AValue: Single);
begin
  FMarketFee:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetLimitFee(const AValue: Single);
begin
  FLimitFee:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetMarketSell(const AValue: Boolean);
begin
  FUseMarketSell:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetMidPerc(const AValue: Single);
begin
  if AValue<0 then
    FMidPerc:=AValue
  else
    FMidPerc:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetMidSellPerc(const AValue: Single);
begin
  FMidSellPerc:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetMinProfit(const AValue: Single);
begin
  FMinProfit:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetMinReduction(const AValue: Single);
begin
  FMinReduction:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetOnlyLower(const AValue: Boolean);
begin
  FOnlyLower:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetOnlyProfit(const AValue: Boolean);
begin
  FOnlyProfit:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetSmallPerc(const AValue: Single);
begin
  if AValue<0 then
    FSmallPerc:=AValue
  else
    FSmallPerc:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetSmallSellPerc(const AValue: Single);
begin
  FSmallSellPerc:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetUseMarketBuy(const AValue: Boolean);
begin
  FUseMarketBuy:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetGTFOPerc(const AValue: Single);
begin
  FGTFOPerc:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetIgnoreProfit(const AValue: Single);
begin
  FIgnoreProfitPerc:=AValue;
end;

procedure TTierStrategyGDAXImpl.InitChannel;
var
  LGTFO,
  LLargeBuy,
  LSmallBuy,
  LSmallSell,
  LLargeSell:IChannel;
begin
  //todo - these numbers are "magic" right now, should break them out
  //into a properties maybe

  LGTFO:=FChannel.Add(GTFO,-4,-4.5)[GTFO];
  LGTFO.OnLower:=GTFOLow;
  LGTFO.OnUpper:=GTFOUp;

  LLargeBuy:=FChannel.Add(LARGE_BUY,-2.3,-3)[LARGE_BUY];
  LLargeBuy.OnLower:=LargeBuyUp;
  LLargeBuy.OnUpper:=LargeBuyLow;

  LSmallBuy:=FChannel.Add(SMALL_BUY,-0.5,-1.5)[SMALL_BUY];
  LSmallBuy.OnUpper:=SmallBuyUp;
  LSmallBuy.OnLower:=SmallBuyLow;

  LSmallSell:=FChannel.Add(SMALL_SELL,1.5,0.5)[SMALL_SELL];
  LSmallSell.OnUpper:=SmallSellUp;
  LSmallSell.OnLower:=SmallSellLow;

  LLargeSell:=FChannel.Add(LARGE_SELL,3,2.3)[LARGE_SELL];
  LLargeSell.OnUpper:=LargeSellUp;
  LLargeSell.OnLower:=LargeSellLow;
end;

procedure TTierStrategyGDAXImpl.GTFOUp(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('GTFOUp::direction is ' + IntToStr(Ord(ADirection)));
  //entering or exiting this channel from the upper bounds puts us in a
  //"watch" mode for GTFO by toggling the "dont buy" flag
  case ADirection of
   cdEnter: FDontBuy:=True;
   cdExit: FDontBuy:=False;
 end;
end;

procedure TTierStrategyGDAXImpl.GTFOLow(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('GTFOLow::direction is ' + IntToStr(Ord(ADirection)));
  //we need to gtfo...
  case ADirection of
    cdExit: FSellItAllNow:=True;
    cdEnter: FSellItAllNow:=False;
  end;
end;

procedure TTierStrategyGDAXImpl.LargeBuyUp(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('LargeBuyUp::direction is ' + IntToStr(Ord(ADirection)));
  //if we break the upper bounds, we're probably going higher
  case ADirection of
    cdExit: FLargeBuy:=True;
  end;
end;

procedure TTierStrategyGDAXImpl.LargeBuyLow(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('LargeBuyLow::direction is ' + IntToStr(Ord(ADirection)));
  //entering from the lower bound of this channel means it's a good oppurtunity
  //to buy in, while exiting, means hold off
  case ADirection of
    cdEnter: FLargeBuy:=True;
  end;
end;

procedure TTierStrategyGDAXImpl.SmallBuyUp(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('SmallBuyUp::direction is ' + IntToStr(Ord(ADirection)));
  //if we break the upper bounds, we're probably going higher
  case ADirection of
    cdExit: FSmallBuy:=True;
  end;
end;

procedure TTierStrategyGDAXImpl.SmallBuyLow(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('SmallBuyLow::direction is ' + IntToStr(Ord(ADirection)));
  //entering from the lower bound of this channel means it's a good oppurtunity
  //to buy in, while exiting, means hold off
  case ADirection of
    cdEnter: FSmallBuy:=True;
  end;
end;

procedure TTierStrategyGDAXImpl.SmallSellUp(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('SmallSellUp::direction is ' + IntToStr(Ord(ADirection)));
  //entering/exiting both trigger a sell
  case ADirection of
    cdEnter,cdExit: FSmallSell:=True;
  end;
end;

procedure TTierStrategyGDAXImpl.SmallSellLow(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('SmallSellLow::direction is ' + IntToStr(Ord(ADirection)));
  //entering/exiting both trigger a sell
  case ADirection of
    cdEnter,cdExit: FSmallSell:=True;
  end;
end;

procedure TTierStrategyGDAXImpl.LargeSellUp(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('LargeSellUp::direction is ' + IntToStr(Ord(ADirection)));
  //large sell exiting puts us into to large sell mode, while
  //entering puts us back to mid sell
  case ADirection of
    cdExit: FLargeSell:=True;
    cdEnter: FMidSell:=True;
  end;
end;

procedure TTierStrategyGDAXImpl.LargeSellLow(const ASender: IChannel;
  const ADirection: TChannelDirection);
begin
  PositionSuccess;
  LogInfo('LargeSellLow::direction is ' + IntToStr(Ord(ADirection)));
  //the lower channel controls mid-range sell oppurtunities
  case ADirection of
    cdEnter,cdExit: FMidSell:=True;
  end;
end;

function TTierStrategyGDAXImpl.DoFeed(const ATicker: ITicker;
  const AManager: IOrderManager; const AFunds, AInventory, AAAC: Extended; out
  Error: String): Boolean;
var
  I:Integer;
  LID:String;
  LTicker:ITickerGDAX;
  LSize:TPositionSize;
  LOrderSize,
  LMin:Extended;
  LPerc,
  LOrderSellTot,
  LOrderBuyTot:Single;
  LSell,
  LAllowLoss:Boolean;
  LGDAXOrder:IGDAXOrder;
  LDetails:IOrderDetails;
  LChannel:IChannel;
  LCriteria:TActiveCriteriaDetails;
  LSelf: ITierStrategyGDAX;
begin
  Result:=inherited DoFeed(ATicker, AManager, AFunds, AInventory, AAAC, Error);
  if not Result then
    Exit;
  Result:=False;
  try
    //feed the channel
    if not FChannel.Feed(ATicker,AManager,AFunds,AInventory,AAAC,Error) then
      Exit;

    if not FChannel.IsReady then
    begin
      LogInfo(
        Format(
          'window is not ready [size]:%d [collected]:%d',
          [
            FChannel.WindowSizeInMilli,
            FChannel.CollectedSizeInMilli
          ]
        )
      );
      Exit(True);
    end;

    //initialize active criteria details
    LSelf:=Self As ITierStrategyGDAX;
    with LCriteria do
    begin
      AAC:=AAAC;
      Funds:=AFunds;
      TotalFunds:=AFunds + AAAC * AInventory;
      Inventory:=AInventory;
      Ticker:=@ATicker;
      Strategy:=@LSelf;
      Data:=FActiveCriteriaData;
    end;

    //log the channels' state
    LogInfo('DoFeed::[StdDev]:' + FloatToStr(FChannel.StdDev));
    for I:=0 to Pred(FChannel.Count) do
    begin
      LChannel:=FChannel.ByIndex[I];
      LogInfo('DoFeed::channel ' + LChannel.Name + ' ' +
        '[anchor]:' + FloatToStr(LChannel.AnchorPrice) + ' ' +
        '[lower]:' + FloatToStr(LChannel.Lower) + ' ' +
        '[upper]:' + FloatToStr(LChannel.Upper)
      );
      LChannel:=nil;
    end;

    //cast to gdax ticker
    LTicker:=ATicker as ITickerGDAX;
    LMin:=RoundTo(LTicker.Ticker.Product.BaseMinSize,-8);

    //initialize the order
    LGDAXOrder:=TGDAXOrderImpl.Create;
    LGDAXOrder.Product:=LTicker.Ticker.Product;

    //get whether or not we should make a position
    if GetPosition(AInventory,LSize,LPerc,LSell)
      or GetFixedSellPosition(AInventory, AAAC, LTicker, LSize, LPerc, LSell) then
    begin
      //this will remove any old limit orders outstanding
      ClearOldPositions(AManager);

      //see if we need to place a sell
      if LSell then
      begin
        LogInfo('DoFeed::sell logic reached');

        //perform pre-processing checks before other
        LCriteria.IsBuy:=False;
        if not ActiveCriteriaCheck(@LCriteria) then
        begin
          LogInfo('DoFeed::active criteria checks returned false, exiting sell');
          Exit(True);
        end;

        //bail if zero was specified
        if LPerc <= 0 then
        begin
          LogInfo('DoFeed::sell::percentage is 0, exiting');
          Exit(True);
        end;

        //set the order size based off the percentage returned to us
        LOrderSize:=RoundTo(Abs(AInventory * LPerc),-8);

        if LOrderSize > AInventory then
          LOrderSize := AInventory;

        //now make sure we respect the min size (ie. can only sell
        //in increments of min increment, so min order size of 1.0 inc
        //of 1.0, and our calc returned 3.5, we would have to sell 3)
        if LOrderSize > 0 then
        begin
          //this code is for a suspect bug in cb quote inc for small
          //coins (where min unit is whole number)
          if RoundTo(LMin,-1) >= 1 then
            LOrderSize:=Trunc(LOrderSize)
          else
            LOrderSize:=Trunc(LOrderSize / LMin) * LMin;
        end;

        //last catch to see if our calculation would be less than min
        //but we have at least min size inventory remaining to sell
        if (RoundTo(LOrderSize,-8) <= LMin) and (RoundTo(AInventory,-8) >= LMin) then
        begin
          LogInfo('DoFeed::SellMode::order is small, but we have at least min setting size of order to min');
          LOrderSize:=LMin;
        end;

        //check to see if we have enough inventory to perform a sell
        if (RoundTo(LOrderSize,-8) < RoundTo(LMin,-8)) or (RoundTo(LOrderSize,-8) > RoundTo(AInventory,-8)) then
        begin
          LogInfo(Format('DoFeed::SellMode::%s is lower than min size or no inventory',[FloatToStr(LOrderSize)]));
          LogInfo('DoFeed::SellMode::clearing signals');

          //although this is not a "success" we have no inventory, and should still should clear the signals
          //to allow for buys to be acted on since sells are prioritized
          PositionSuccess;
          Exit(True);
        end;

        //based on the threshold percentage and how much inventory to funds
        //we currently have, we may allow selling at a loss or if we need to gtfo
        LAllowLoss:=
          (
            (FIgnoreProfitPerc > 0)
            and ((AFunds + (AInventory * AAAC)) > 0)
            and (((AInventory * AAAC) / (AFunds + (AInventory * AAAC))) >= FIgnoreProfitPerc)
          )
          or (
            (LSize = psGTFO)
            and (FGTFOPerc > 0)
          );

        //before doing any other calcs/comparisons, see if we are in
        //choppy conditions, if so get out
        if FAvoidChop and ChoppyWaters then
        begin
          LogInfo('DoFeed::SellMode::choppy waters cap''n, gon hold off from sellin.');
          PositionSuccess;
          Exit(True);
        end;

        if LAllowLoss then
          LogInfo('DoFeed::SellMode::conditions are right to allow selling at a loss');

        //if we are in only profit mode, we need to some validation before
        //placing an order
        if FOnlyProfit and (not LAllowLoss) then
        begin
          //figure out the total amount depending on limit/market
          if FUseMarketSell then
          begin
            //figure the amount of currency we would receive minus the fees
            LOrderSellTot:=(LOrderSize * LTicker.Ticker.Ask) - (FMarketFee * LOrderSize * LTicker.Ticker.Ask);
            LGDAXOrder.OrderType:=otMarket;
            LGDAXOrder.Price:=LTicker.Ticker.Ask;
            LogInfo('DoFeed::SellMode::using market sell, with OnlyProfit, total sell amount would be ' + FloatToStr(LOrderSellTot));
          end
          else
          begin
            LOrderSellTot:=(LOrderSize * LTicker.Ticker.Ask) - (FLimitFee * LOrderSize * LTicker.Ticker.Ask);
            LGDAXOrder.OrderType:=otLimit;
            LGDAXOrder.Price:=LTicker.Ticker.Ask;
            LogInfo('DoFeed::SellMode::using limit sell, with OnlyProfit, total sell amount would be ' + FloatToStr(LOrderSellTot));
          end;

          //if the cost to sell is less-than aquisition of size, we would be
          //losing money, and that is not allowed in this case
          if LOrderSellTot < (AAAC * LOrderSize) then
          begin
            LogInfo('DoFeed::SellMode::sell would result in loss, and OnlyProfit is on, exiting');
            Exit(True)
          end;

          //if we have a minimum profit, see if we've met the criteria
          if (FMinProfit > 0)
            and ((LOrderSellTot - (AAAC * LOrderSize)) / (AAAC * LOrderSize) < FMinProfit) then
          begin
            LogInfo('DoFeed::SellMode::a minimum profit is set and the current ask price is less, exiting');
            Exit(True);
          end;
        end
        else
        begin
          if FUseMarketSell then
            LGDAXOrder.OrderType:=otMarket
          else
            LGDAXOrder.OrderType:=otLimit;

          //set the price
          LGDAXOrder.Price:=LTicker.Ticker.Ask;
        end;

        //set the order side to sell
        LGDAXOrder.Side:=osSell;
        LGDAXOrder.Size:=LOrderSize;
      end
      //otherwise we are seeing if we can open a buy position
      else
      begin
        LogInfo('DoFeed::buy logic');

        //perform pre-processing checks before other
        LCriteria.IsBuy:=True;
        if not ActiveCriteriaCheck(@LCriteria) then
        begin
          LogInfo('DoFeed::active criteria checks returned false, exiting buy');
          Exit(True);
        end;

        if LPerc <= 0 then
        begin
          LogInfo('DoFeed::buy::percentage is 0, exiting');
          Exit(True);
        end;

        //now account for buy scaling
        LPerc := CalculateScaleBuyPercent(AFunds, AInventory, AAAC, LPerc);

        //see if we have enough funds to cover either a limit or market
        LOrderBuyTot:=Abs(RoundTo(AFunds * LPerc,-8));

        if LOrderBuyTot > AFunds then
        begin
          LogInfo(Format('DoFeed::BuyMode::would need %f funds, but only %f',[LOrderBuyTot,AFunds]));
          Exit(True);
        end;

        //set the order size based on the amount of funds we have
        //and how many units of min this will purchase
        LOrderSize:=Trunc(LOrderBuyTot / LTicker.Ticker.Bid / LMin) * LMin;

        //our percentage would be too small, but we have at least min, so set
        //to min in order to make a purchase
        if (LOrderSize < LMin)
          and (RoundTo(AFunds / LTicker.Ticker.Bid,-8) >= LMin)
        then
          LOrderSize:=LMin;

        //check to see the order size isn't too small
        if LOrderSize < LMin then
        begin
          LogInfo(Format('DoFeed::BuyMode::%s is lower than min size',[FloatToStr(LOrderSize)]));
          LogInfo('DoFeed::BuyMode::clearing signals');
          PositionSuccess;
          Exit(True);
        end;

        //before doing any other calcs/comparisons, see if we are in
        //choppy conditions, if so get out
        if FAvoidChop and ChoppyWaters then
        begin
          LogInfo('DoFeed::BuyMode::choppy waters cap''n, gon hold off from buyin.');
          PositionSuccess;
          Exit(True);
        end;

        //simple check to see if bid is lower than aac when requested
        if FOnlyLower and (RoundTo(AInventory,-8) >= LMin) then
        begin
          //initially set this variable to what the AAC would be if a limit
          //order was successful since this will be the most common type of order
          LOrderBuyTot:=((LOrderSize * ((1 + FLimitFee) * LTicker.Ticker.Bid) + (AAAC * AInventory)) / (LOrderSize + AInventory));

          //check to see if the limit order would result in a higher AAC
          if not FUseMarketBuy and (LOrderBuyTot > AAAC) then
          begin
            LogInfo(Format('DoFeed::BuyMode::[new aac]:%f is not lower than [aac]:%f',[LOrderBuyTot,AAAC]));
            Exit(True);
          end
          //account for what the new aac "would" be assuming we get the order
          //placed at this price, with the specified fee. this can't account
          //for slippage, or if the price moves by the time the order is actually
          //made, but it's the best that can be done
          else if FUseMarketBuy and ((AInventory > 0) and (AAAC > 0)) then
          begin
            //use this variable to hold what aac would be if successfull accounting for fee
            LOrderBuyTot:=((LOrderSize * ((1 + FMarketFee) * LTicker.Ticker.Bid) + (AAAC * AInventory)) / (LOrderSize + AInventory));

            //check to see if the estimated aac is not greater than the current aac
            if LOrderBuyTot > AAAC then
            begin
              LogInfo(Format('DoFeed::BuyMode::market order shows higher [aac]:%f than [current aac]:%f',[LOrderBuyTot,AAAC]));
              Exit(True);
            end;
          end;

          //make sure we are reducing by the minimum amount, using the calculated
          //new aac, against the old
          if (FMinReduction > 0)
            and (((AAAC - LOrderBuyTot) / AAAC) < FMinReduction) then
          begin
            LogInfo('DoFeed::BuyMode::a minimum reduction is set, and the current bid would not lower AAC enough, exiting');
            Exit(True);
          end;
        end;

        //update order depending on type
        if FUseMarketBuy then
          LGDAXOrder.OrderType:=otMarket
        else
          LGDAXOrder.OrderType:=otLimit;

        //set the price
        LGDAXOrder.Price:=LTicker.Ticker.Bid;

        //set the order up for buying
        LGDAXOrder.Side:=osBuy;
        LGDAXOrder.Size:=LOrderSize;
      end;

      LogInfo(Format('DoFeed::[buyorder]:%s [limit]:%s [price]:%f [size]:%f',[BoolToStr(LGDAXOrder.Side=osBuy,True),BoolToStr(LGDAXOrder.OrderType=otLimit,True),LGDAXOrder.Price,LGDAXOrder.Size]));

      //call the manager to place the order
      LDetails:=TGDAXOrderDetailsImpl.Create(LGDAXOrder);
      if not AManager.Place(
        LDetails,
        LID,
        Error
      ) then
        Exit;

      //add limit order id's to a list so we can periodically check them
      //if we are switching positions
      if LGDAXOrder.OrderType=otLimit then
        FIDS.Add(LID);

      //if we were successful calling the order manager, report success
      PositionSuccess;
      Result:=True;
    end
    else
      Exit(True);
  except on E:Exception do
    Error:=E.Message;
  end;
end;

function TTierStrategyGDAXImpl.GetPosition(const AInventory: Extended; out
  Size: TPositionSize; out Percentage: Single; out Sell: Boolean): Boolean;
begin
  Result:=False;
  Sell:=False;

  //prioritize an all sell above everything
  if FSellItAllNow and (AInventory > 0) and (FGTFOPerc > 0) then
  begin
    Sell:=True;
    Percentage:=FGTFOPerc;
    Size:=psGTFO;
    Exit(True);
  end
  else
  begin
    //can't sell without inventory, this check ensures buy signals don't get ignored
    if AInventory > 0 then
    begin
      //check for any sells weighted highest to lowest in priority
      if FLargeSell and (FLargeSellPerc > 0) then
      begin
        Sell:=True;
        Percentage:=FLargeSellPerc;
        Size:=psLarge;
        Exit(True);
      end
      else if FMidSell and (FMidSellPerc > 0) then
      begin
        Sell:=True;
        Percentage:=FMidSellPerc;
        Size:=psMid;
        Exit(True);
      end
      else if FSmallSell and (FSmallSellPerc > 0) then
      begin
        Sell:=True;
        Percentage:=FSmallSellPerc;
        Size:=psSmall;
        Exit(True);
      end;
    end;

    //check for any buys weighted highest to lowest in priority
    if not FDontBuy then
    begin
      if FLargeBuy and (FLargePerc > 0) then
      begin
        Sell:=False;
        Percentage:=FLargePerc;
        Size:=psLarge;
        Exit(True);
      end
      else if FSmallBuy and (FSmallPerc > 0) then
      begin
        Sell:=False;
        Percentage:=FSmallPerc;
        Size:=psSmall;
        Exit(True);
      end;
    end;
  end;
end;

function TTierStrategyGDAXImpl.GetFixedSellPosition(const AInventory: Extended;
  const AAAC: Extended; const ATicker: ITickerGDAX; out Size: TPositionSize;
  out Percentage: Single; out Sell: Boolean): Boolean;
begin
  Result := False;

  if ATicker.Ticker.Ask < AAAC then
    Exit;

  if (AAAC <= 0) or (AInventory <= 0) then
    Exit;

  //if the asking price is at least the profit, then sell
  if (1 - ATicker.Ticker.Ask / AAAC) >= FMinProfit then
  begin;
    Size := psSmall;
    Percentage := FSmallSellPerc;

    if Percentage <= 0 then
    begin
      Size := psMid;
      Percentage := FMidSellPerc;
    end;

    if Percentage <= 0 then
    begin
      Size := psLarge;
      Percentage := FLargeSellPerc;
    end;

    Sell := True;
    Result := True;
  end;
end;

procedure TTierStrategyGDAXImpl.PositionSuccess;
begin
  //init all signal flags to false
  FDontBuy:=False;
  FLargeBuy:=False;
  FSmallBuy:=False;
  FLargeSell:=False;
  FMidSell:=False;
  FSmallSell:=False;
  FSellItAllNow:=False;
end;

procedure TTierStrategyGDAXImpl.ClearOldPositions(const AManager: IOrderManager);
var
  I:Integer;
  LDetails:IOrderDetails;
  LError:String;
begin
  //will iterate all managed positions and cancel those not completed
  for I:=0 to Pred(FIDS.Count) do
  begin
    if AManager.Exists[FIDS[I]] then
    begin
      //only cancel if we have an active order
      if AManager.Status[FIDS[I]] = omActive then
        //if we fail, log it and don't clear the managed list yet
        if not AManager.Cancel(FIDS[I],LDetails,LError) then
        begin
          LogError('ClearOldPositions::' + LError);
          Exit;
        end;
    end;
  end;

  //if everything went well, clear the positions
  FIDS.Clear;
end;

function TTierStrategyGDAXImpl.ChoppyWaters: Boolean;
var
  I: Integer;
  LAvgAnc,
  LAvgDev,
  LChopInd: Single;
type
  TRange = record
    Lower,
    Upper,
    StdDev,
    Percent : Single;
    Count : Integer;
  end;
  TRanges = TArray<TRange>;

  (*
    build the range array from the channels and tickers collected
  *)
  procedure BuildRanges(out Ranges : TRanges; out Coverage : Single);
  var
    I, J, LFound : Integer;
    LRange : TRange;
    LTickers : TTickers;
  begin
    SetLength(Ranges, FChannel.Count);
    LFound := 0;

    //add all the ranges found in the channels
    for I := 0 to Pred(FChannel.Count) do
    begin
      //update
      LRange.Count := 0;
      LRange.Lower := FChannel.ByIndex[I].Lower;
      LRange.Upper := FChannel.ByIndex[I].Upper;

      //channels are defined below and above the mean, so we need to find
      //if this is a "lower" or "upper" style channel, and use the appropriate
      //std dev property in that case
      if Abs(FChannel.ByIndex[I].UpperStdDev) > Abs(FChannel.ByIndex[I].LowerStdDev) then
        LRange.StdDev := Abs(FChannel.ByIndex[I].UpperStdDev)
      else
        LRange.StdDev := Abs(FChannel.ByIndex[I].LowerStdDev);

      //insert to array
      Ranges[I] := LRange;
    end;

    //now add to the distribution by comparing the tickers price to the range
    LTickers := FChannel.Tickers;
    for I := 0 to Pred(LTickers.Count) do
      for J := 0 to High(Ranges) do
      begin
        LRange := Ranges[J];

        //check if ticker price is between the range
        if (LTickers[I].Price <= LRange.Upper)
          and (LTickers[I].Price <= LRange.Upper)
        then
        begin
          //found, so increment count
          Inc(LRange.Count);

          //update array value
          Ranges[J] := LRange;

          Inc(LFound);

          //get out of range loop
          Break;
        end;
      end;

    //find the coverage
    for I := 0 to High(Ranges) do
    begin
      LRange := Ranges[I];
      LRange.Percent := (LRange.Count / LFound) * 100;
      Ranges[I] := LRange;
    end;

    //update coverage
    Coverage := (LFound / LTickers.Count) * 100;
  end;

  (*
    sorts all readings into channel based populations. will count
    the total occurences and "adjust" the deviation so that
    it can be used for subtracting fees from. if this turns out to be
    stupid, then perhaps using a confidence interval might work?
  *)
  function AdjustedDeviation(const AStdDev : Single) : Single;
  var
    LRanges : TRanges;
    LCoverage : Single;
    I : Integer;
    LDistributions : String;
  begin
    Result := 0;

    //build the range array (distribution)
    BuildRanges(LRanges, LCoverage);

    //get the aggregated result
    LDistributions := '';
    for I := 0 to High(LRanges) do
    begin
      Result := Result + ((AStdDev * LRanges[I].StdDev) * LRanges[I].Percent);
      LDistributions := LDistributions + Format(
        '[Range]:(L->U) %f .. %f [StdDev]:%f [Count]:%s [Percent]:%f' + ' ',
        [
          LRanges[I].Lower,
          LRanges[I].Upper,
          LRanges[I].StdDev,
          IntToStr(LRanges[I].Count),
          LRanges[I].Percent
        ]
      );
    end;

    LogInfo(LDistributions);

    //divide by the coverage to get the adjusted deviation
    Result := Result / LCoverage;

    LogInfo(
      Format(
        'ChoppyWaters::AdjustedDeviation::[Coverage]:%f [Dev]:%f [AdjustedDev]:%f',
        [LCoverage, AStdDev, Result]
      )
    );
  end;

begin
  Result := False;
  LChopInd := 0;
  LAvgAnc:=0;
  LAvgDev:=0;

  LogInfo('ChoppyWaters::starting');

  //if we don't care about choppy market, then exit
  if not FAvoidChop then
  begin
    LogInfo('ChoppyWaters::not avoiding chop, exiting');
    Exit;
  end;

  //find the average anchor price and deviation
  for I := 0 to Pred(FChannel.Count) do
  begin
    LAvgAnc := LAvgAnc + FChannel.ByIndex[I].AnchorPrice;
    LAvgDev := LAvgDev + FChannel.ByIndex[I].StdDev;
  end;

  LAvgAnc := LAvgAnc / FChannel.Count;
  LAvgDev := LAvgDev / FChannel.Count;

  LogInfo(
    Format(
      'ChoppyWaters::[AvgAnchor]:%s [AvgDeviation]:%s',
      [FloatToStr(LAvgAnc),FloatToStr(LAvgDev)]
    )
  );

  //find the total fees, once we have this we can see if the market is "choppy"
  //(doesn't mean profit can be reached
  //just means we won't be burning our ass in rapid succession)
  if UseMarketBuy then
    LChopInd := MarketFee
  //limit buy
  else
    LChopInd := LimitFee;

  { allow fall through to account for both sides }

  //market sell
  if UseMarketSell then
    LChopInd := LChopInd + MarketFee
  //limit sell
  else
    LChopInd := LChopInd + LimitFee;

  //now use the fee to see what the "round trip" (buy/sell) would result in
  //after adjusting the deviation according to our distribution
  LChopInd := AdjustedDeviation(LAvgDev) / LAvgAnc - LChopInd;

  LogInfo('ChoppyWaters::[ChopIndicator]:' + FloatToStr(LChopInd));

  //as long as the delta is greater than zero, there is a chance for some profit
  //so return choppy when we aren't
  Result:=LChopInd < 0;
end;

function TTierStrategyGDAXImpl.ActiveCriteriaCheck(
  const ADetails: PActiveCriteriaDetails): Boolean;
var
  I: Integer;
begin
  //default active to true
  Result:=True;
  if Length(FActiveCriteria) < 1 then
    Exit(True)
  else
  begin
    //iterate our callbacks and call each one
    for I := 0 to High(FActiveCriteria) do
    begin
      if Assigned(FActiveCriteria[I]) then
        FActiveCriteria[I](ADetails,Result);

      //return one of the checks fails
      if not Result then
        Exit;
    end;
  end;
end;

function TTierStrategyGDAXImpl.GetAvoidChop: Boolean;
begin
  Result:=FAvoidChop;
end;

procedure TTierStrategyGDAXImpl.SetAvoidChop(const AValue: Boolean);
begin
  FAvoidChop:=AValue;
end;

procedure TTierStrategyGDAXImpl.SetMaxScaleBuy(const AValue: Single);
begin
  FMaxScaleBuy := AValue;
end;

function TTierStrategyGDAXImpl.CalculateScaleBuyPercent(const AFunds,
  AInventory, AAAC: Extended; const ABuyPerc: Single): Single;
var
  LTotalFunds,
  LFundUsage: Extended;
begin
  Result := ABuyPerc;

  //no buy scaling set, exit
  if FMaxScaleBuy <= 0 then
    Exit;

  //find the fund utilization percentage
  LTotalFunds := (AInventory * AAAC + AFunds);

  if LTotalFunds <= 0 then
    Exit;

  LFundUsage := 1 - AFunds / LTotalFunds;

  //now with the fund usage, we can apply the scale to the provided buy percent
  Result := ABuyPerc + (ABuyPerc * (LFundUsage * FMaxScaleBuy));

  //can't buy negative amounts
  if Result < 0 then
    Result := 0;

  LogInfo(Format('CalculateScaleBuyPercent::buy scaling applied [orig]:%f [new]:%f', [ABuyPerc, Result]));
end;

function TTierStrategyGDAXImpl.GetFixedProfit: Boolean;
begin
  Result := FFixed;
end;

procedure TTierStrategyGDAXImpl.SetFixedProfit(const AValue: Boolean);
begin
  FFixed := AValue;
end;

constructor TTierStrategyGDAXImpl.Create(const AOnInfo, AOnError,
  AOnWarn: TStrategyLogEvent);
begin
  inherited Create(AOnInfo,AOnError,AOnWarn);
  FChannel := TChannelStrategyImpl.Create(AOnInfo,AOnError,AOnWarn);
  FIDS := TFPGList<String>.Create;
  FSmallPerc := 0;
  FMidPerc := 0;
  FLargePerc := 0;
  FSmallSellPerc := 0;
  FMidSellperc := 0;
  FLargeSellPerc := 0;
  FMarketFee := 0.003;//account for slippage on market orders
  FLimitFee := 0.0015;
  FMinProfit := 0;
  FMinReduction := 0;
  FUseMarketBuy := False;
  FUseMarketSell := False;
  FIgnoreProfitPerc := 0;
  FGTFOPerc := 0;
  FAvoidChop := False;
  FMaxScaleBuy := 0;
  FFixed := False;
  InitChannel;
end;

destructor TTierStrategyGDAXImpl.Destroy;
begin
  FChannel:=nil;
  FIDS.Free;
  inherited Destroy;
end;

end.

