unit utilities.tickerparser.main;

{$mode delphi}{$H+}

interface

uses
  Classes,
  SysUtils,
  Forms,
  Controls,
  Graphics,
  Dialogs,
  ExtCtrls,
  StdCtrls,
  ComCtrls,
  Buttons,
  fgl,
  gdax.api.ticker,
  gdax.api.types,
  delilah.ticker,
  utilities.mock.manager,
  delilah.types,
  delilah,
  ledger,
  ui.strategy;

type

  { TTickerLoader }

  TTickerLoader = class(TGDAXTickerImpl)
  private
    FAAC: Extended;
    FFunds: Extended;
    FInv: Extended;
    FJSON : String;
    FIsBuy,
    FIsSell: Boolean;
    FProf: Extended;
    function GetIsBuy: Boolean;
    function GetIsSell: Boolean;
    function GetJSON: String;
    procedure SetIsBuy(const AValue: Boolean);
    procedure SetIsSell(const AValue: Boolean);
  public
    property JSON : String read GetJSON;
    property IsBuy : Boolean read GetIsBuy write SetIsBuy;
    property IsSell : Boolean read GetIsSell write SetIsSell;
    property Funds : Extended read FFunds write FFunds;
    property Inventory : Extended read FInv write FInv;
    property AAC : Extended read FAAC write FAAC;
    property Profit : Extended read FProf write FProf;

    procedure Load(const AJSON : String);

    constructor Create; override;
  end;

  TTickerList = TFPGInterfacedObjectList<TTickerLoader>;

  { TTickerParser }
  (*
    simple utility form to load ticker save files output by SimpleBot
    into spreadsheet readable formats
  *)
  TTickerParser = class(TForm)
    btn_edit_strategy: TButton;
    btn_load: TButton;
    btn_open_picker_csv: TSpeedButton;
    btn_save_csv: TButton;
    btn_save_simulate: TButton;
    btn_cance_simulate: TButton;
    btn_add_strategy: TButton;
    btn_save_tickers: TButton;
    edit_product: TEdit;
    edit_funds: TEdit;
    edit_directory: TEdit;
    edit_directory_csv: TEdit;
    edit_fee_perc: TEdit;
    edit_product_min: TEdit;
    lbl_decimate_info: TLabel;
    lbl_demo_info: TLabel;
    lbl_load_info: TLabel;
    memo_load_order: TMemo;
    pctrl_main: TPageControl;
    pnl_ctrls: TPanel;
    btn_open_picker: TSpeedButton;
    dialog_directory: TSelectDirectoryDialog;
    pnl_ctrls1: TPanel;
    pnl_ctrls_simulate: TPanel;
    progress_simulate: TProgressBar;
    scroll_strategies: TScrollBox;
    Simulate: TTabSheet;
    trackbar_decimate: TTrackBar;
    ts_export: TTabSheet;
    ts_load: TTabSheet;
    procedure btn_add_strategyClick(Sender: TObject);
    procedure btn_cance_simulateClick(Sender: TObject);
    procedure btn_edit_strategyClick(Sender: TObject);
    procedure btn_loadClick(Sender: TObject);
    procedure btn_open_pickerClick(Sender: TObject);
    procedure btn_open_picker_csvClick(Sender: TObject);
    procedure btn_save_csvClick(Sender: TObject);
    procedure btn_save_simulateClick(Sender: TObject);
    procedure btn_save_tickersClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
  strict private
    FTickers : TTickerList;
    FStrategies : TStrategies;
    FCancelSim,
    FDemo: Boolean;
    FCurrentSimIndex : Integer;
    FCurrentEngine : IDelilah;
    FStrategyList : TFPGObjectList<TCheckBox>;
    FOnStart,
    FOnFinish : TNotifyEvent;

    function GetDemo: Boolean;
    function GetEngine: IDelilah;
    function GetOnFinish: TNotifyEvent;
    function GetOnStart: TNotifyEvent;
    function GetStrategies: TStrategies;
    procedure ConfigureNewStrategy(const AName : String = '';
      const AStrategy : IStrategy = nil);
    procedure LoadStrategies(const AStrategies : TStrategies);
    procedure MonitorOrderPlace(Const ADetails:IOrderDetails; Const AID:String);
    procedure SaveNewStrategy(const ASender : TConfigureStrategy; const AName : String;
      const AStrategy : IStrategy);
    procedure SetDemo(const AValue: Boolean);
    function DecimationPercent : Single;
    procedure SetOnFinish(const AValue: TNotifyEvent);
    procedure SetOnStart(const AValue: TNotifyEvent);
  strict protected
    procedure PickDirectory;

  public
    property OnStartSimulate : TNotifyEvent read GetOnStart write SetOnStart;
    property OnFinishSimulate : TNotifyEvent read GetOnFinish write SetOnFinish;

    property DemoMode : Boolean read GetDemo write SetDemo;
    property Strategies : TStrategies read GetStrategies;
    property Engine : IDelilah read GetEngine;
    property LoadedTickers : TTickerList read FTickers;

    procedure LoadFiles(const AFiles : TStrings; const ADecimation : Single = -1);
    procedure SimulateStrategy(const ASilentFinish : Boolean = False);
    procedure SaveCSV(const AFileName : String = ''; const ASilentFinish : Boolean = False);
    procedure SaveTickerFile(const AFileName : String);
  end;

var
  TickerParser: TTickerParser;

implementation
uses
  FileUtil,
  strutils,
  delilah.ticker.gdax,
  delilah.strategy.gdax.sample,
  gdax.api.products,
  ui.strategypicker,
  ui.strategyconfig,
  ui.strategy.tiers,
  ui.strategy.acceleration.gdax,
  ui.strategy.bobber
  {$IFDEF WINDOWS}
  ,JwaWindows
  {$ENDIF};

{$R *.lfm}

{ TTickerParser }

procedure TTickerParser.btn_open_pickerClick(Sender: TObject);
begin
  if dialog_directory.Execute then
  begin
    edit_directory.Text := dialog_directory.FileName;
    edit_directory_csv.Text := edit_directory.Text + '\output.csv';
  end;
end;

procedure TTickerParser.btn_open_picker_csvClick(Sender: TObject);
begin
  if dialog_directory.Execute then
    edit_directory_csv.Text := dialog_directory.FileName;
end;

procedure TTickerParser.btn_save_csvClick(Sender: TObject);
begin
  SaveCSV;
end;

procedure TTickerParser.btn_save_simulateClick(Sender: TObject);
begin
  SimulateStrategy;
end;

procedure TTickerParser.btn_save_tickersClick(Sender: TObject);
var
  LDialog: TSaveDialog;
begin
  LDialog := TSaveDialog.Create(nil);
  try
    if LDialog.Execute then
      SaveTickerFile(LDialog.FileName);
  finally
    LDialog.Free;
  end;
end;

procedure TTickerParser.FormCreate(Sender: TObject);
begin
  FTickers := TTickerList.Create;
  FStrategies := TStrategies.Create;
  FStrategyList := TFPGObjectList<TCheckBox>.Create;
  pctrl_main.ActivePage := ts_load;
  progress_simulate.Visible := False;
  trackbar_decimate.Position := 0;
end;

procedure TTickerParser.FormDestroy(Sender: TObject);
begin
  FTickers.Free;
  FStrategies.Free;
end;

procedure TTickerParser.FormShow(Sender: TObject);
begin
  DemoMode := DemoMode;
end;


procedure TTickerParser.LoadStrategies(const AStrategies : TStrategies);
var
  I: Integer;
begin
  //add checked strategies
  if not FDemo then
  begin
    for I := 0 to Pred(FStrategyList.Count) do
      if FStrategyList[I].Checked then
        AStrategies.Add(FStrategies[FStrategyList[I].Tag])
  end
  //otherwise, add them all
  else
    for I := 0 to Pred(FStrategies.Count) do
      AStrategies.Add(FStrategies[I]);
end;

function TTickerParser.GetStrategies: TStrategies;
begin
  Result := FStrategies;
end;

function TTickerParser.GetDemo: Boolean;
begin
  Result := FDemo;
end;

function TTickerParser.GetEngine: IDelilah;
begin
  Result := FCurrentEngine;
end;

function TTickerParser.GetOnFinish: TNotifyEvent;
begin
  Result := FOnFinish;
end;

function TTickerParser.GetOnStart: TNotifyEvent;
begin
  Result := FOnStart;
end;

procedure TTickerParser.ConfigureNewStrategy(const AName : String; const AStrategy : IStrategy = nil);
var
  LPicker : TStrategyPicker;
  LConfig : TStrategyHolder;
begin
  LPicker := TStrategyPicker.Create(nil);
  LPicker.Position := poMainFormCenter;

  if LPicker.ShowModal = mrOK then
  begin
    LConfig := TStrategyHolder.Create(nil);
    LConfig.Config := LPicker.Config.Create(nil);
    LConfig.Position := poMainFormCenter;
    LConfig.Config.OnSave := SaveNewStrategy;

    if Assigned(AStrategy) then
    begin
      LConfig.Config.edit_name.Text := AName;
      LConfig.Config.Strategy := AStrategy;
    end;

    LConfig.ShowModal;
    LConfig.Free;
  end;

  LPicker.Free;
end;

procedure TTickerParser.MonitorOrderPlace(const ADetails: IOrderDetails;
  const AID: String);
begin
  if ADetails.OrderType = odBuy then
    FTickers[FCurrentSimIndex].IsBuy := True
  else
    FTickers[FCurrentSimIndex].IsSell := True;
end;

procedure TTickerParser.SaveNewStrategy(const ASender: TConfigureStrategy;
  const AName: String; const AStrategy: IStrategy);
var
  I: Integer;
  LCheck: TCheckBox;
begin
  //remove if exists
  for I := 0 to Pred(FStrategyList.Count) do
    if FStrategyList[I].Caption = AName then
    begin
      FStrategyList[I].Parent := nil;
      FStrategyList.Delete(I);
      Break;
    end;

  //add the configured strategy to the list, as well as parent it
  LCheck := TCheckBox.Create(nil);
  LCheck.Name := 'CheckBoxStrat' + IntToStr(Succ(FStrategies.Count));
  LCheck.Caption := AName;
  LCheck.Tag := FStrategies.Add(AStrategy);
  LCheck.Align := alTop;
  LCheck.Parent := scroll_strategies;

  //add to list
  FStrategyList.Add(LCheck);
end;

procedure TTickerParser.SetDemo(const AValue: Boolean);
begin
  FDemo := AValue;
  lbl_demo_info.Visible := AValue;
  btn_add_strategy.Visible := not AValue;
  btn_edit_strategy.Visible := not AValue;
end;

function TTickerParser.DecimationPercent: Single;
begin
  Result := trackbar_decimate.Position / trackbar_decimate.Max;
end;

procedure TTickerParser.SetOnFinish(const AValue: TNotifyEvent);
begin
  FOnFinish := AValue;
end;

procedure TTickerParser.SetOnStart(const AValue: TNotifyEvent);
begin
  FOnStart := AValue;
end;

procedure TTickerParser.SaveCSV(const AFileName: String;
  const ASilentFinish: Boolean);
var
  LOutput : TStringList;
  I: Integer;
  LFile: String;
begin
  LOutput := TStringList.Create;
  try
    //add headers
    LOutput.Add(
      'price' + ',' +
      'ask' + ',' +
      'bid' + ',' +
      'size' + ',' +
      'volume' + ',' +
      'time' + ',' +
      'is_position' + ',' +
      'is_buy' + ',' +
      'is_sell' + ',' +
      'funds' + ',' +
      'inventory' + ',' +
      'aac' + ',' +
      'profit'
    );

    //output csv rows
    for I := 0 to Pred(FTickers.Count) do
      LOutput.Add(
        FloatToStr(FTickers[I].Price) + ',' +
        FloatToStr(FTickers[I].Ask) + ',' +
        FloatToStr(FTickers[I].Bid) + ',' +
        FloatToStr(FTickers[I].Size) + ',' +
        FloatToStr(FTickers[I].Volume) + ',' +
        DateTimeToStr(FTickers[I].Time) + ',' +
        IfThen(FTickers[I].IsBuy or FTickers[I].IsSell, '1', '') + ',' +
        IfThen(FTickers[I].IsBuy, '1', '') + ',' +
        IfThen(FTickers[I].IsSell, '1', '') + ',' +
        FloatToStr(FTickers[I].Funds) + ',' +
        FloatToStr(FTickers[I].Inventory) + ',' +
        FloatToStr(FTickers[I].AAC) + ',' +
        FloatToStr(FTickers[I].Profit)
      );

    //use input, but fallback to visual filename
    LFile := AFileName;
    if LFile = '' then
      LFile := edit_directory_csv.Text;

    LOutput.SaveToFile(LFile);

    if not ASilentFinish then
      ShowMessage('saved to ' + LFile);
  finally
    LOutput.Free;
  end;
end;

procedure TTickerParser.SaveTickerFile(const AFileName: String);
var
  LFile : TextFile;
  I: Integer;
begin
  AssignFile(LFile, AFileName);
  try
    Rewrite(LFile);

    //write json to the file
    for I := 0 to Pred(FTickers.Count) do
      WriteLn(LFile, FTickers[I].JSON);
  finally
    CloseFile(LFile);
  end;
end;

procedure TTickerParser.SimulateStrategy(const ASilentFinish: Boolean);
var
  LEngine: IDelilah;
  LManager : IMockOrderManager;
  LStep: Int64;
  I: Integer;
  LTicker : ITickerGDAX;
  LError: string;
  LLoader: TTickerLoader;
  LProduct : IGDAXProduct;
  LFunds, LInventory, LTickPrice, LAAC: Extended;
  LFundsLed, LStartingFunds: Extended;
begin
  btn_save_simulate.Enabled := False;
  progress_simulate.Visible := True;

  FCancelSim := False;
  FCurrentSimIndex := -1;

  //create the product that the tickers represent
  //todo - make this configurable or just load from api
  LProduct := TGDAXProductImpl.Create;
  LProduct.BaseCurrency := Copy(edit_product.Text, Pos('-', edit_product.Text), Length(edit_product.Text));
  LProduct.BaseMaxSize := 100000;
  LProduct.BaseMinSize := StrToFloatDef(edit_product_min.Text, 0.001);
  LProduct.ID := edit_product.Text;
  LProduct.QuoteIncrement := LProduct.BaseMinSize;

  //create and setup engine
  LEngine := TDelilahImpl.Create;
  LEngine.OnPlace := MonitorOrderPlace;
  LEngine.Funds := StrToFloatDef(edit_funds.Text, 1000);
  LStartingFunds := LEngine.Funds;
  LEngine.Compound := True;
  FCurrentEngine := LEngine;

  //create and setup order manager
  LManager := TMockOrderManagerImpl.Create;
  LManager.FeePercentage := StrToFloatDef(edit_fee_perc.Text, 0);
  LEngine.OrderManager := LManager;

  //get the strategy to use for simulation and add to the engine
  LoadStrategies(LEngine.Strategies);

  //startup the engine to accept tickers
  LEngine.Start;

  if Assigned(FOnStart) then
    FOnStart(Self);

  progress_simulate.Position := 0;
  LStep := Trunc(FTickers.Count / 20);
  for I := 0 to Pred(FTickers.Count) do
  begin
    {$IFDEF WINDOWS}
    SetThreadExecutionState(ES_CONTINUOUS OR ES_SYSTEM_REQUIRED OR DWORD($00000040));
    {$ENDIF}

    if FCancelSim then
      Break;

    //manager needs the buy and sell prices
    LManager.BuyPrice := FTickers[I].Bid;
    LManager.SellPrice := FTickers[I].Ask;

    //initialize a ticker to feed to the engine
    LLoader := TTickerLoader.Create;
    LLoader.LoadFromJSON(FTickers[I].JSON, LError);
    LTicker := TGDAXTickerImpl.Create(LLoader);
    LTicker.Ticker.Product := LProduct;

    //set the current index so we know what row to append metrics to
    FCurrentSimIndex := I;

    //feed the engine and make some money
    LEngine.Feed(LTicker, LError);

    //ripped from simple bot main form
    LInventory := FCurrentEngine.AvailableInventory;
    LTickPrice := FTickers[FCurrentSimIndex].Price;
    LAAC := FCurrentEngine.AAC;
    LFundsLed := FCurrentEngine.FundsLedger.Balance;

    //update engine info
    FTickers[FCurrentSimIndex].Funds := LFundsLed;
    FTickers[FCurrentSimIndex].Inventory := LInventory;
    FTickers[FCurrentSimIndex].AAC := LAAC;

    FTickers[FCurrentSimIndex].Profit := ((LFundsLed + (LAAC * LInventory)) + LInventory * (LTickPrice - LAAC)) - LStartingFunds;

    //update the progress and process ui messages
    if (I > 0) and (LStep > 0) and (I mod LStep = 0) then
    begin
      progress_simulate.StepBy(5);
      Application.ProcessMessages;
    end;

    if I mod 200 = 0 then
      Application.ProcessMessages;
  end;

  //stop the engine to clear out any data from the strategies since
  //those don't free with the engine freeing
  LEngine.Stop;

  if Assigned(FOnFinish) then
    FOnFinish(Self);

  if not ASilentFinish then
  begin;
    if FCancelSim then
      ShowMessage('Simulation Cancelled :(')
    else
      ShowMessage('Simulation Finished!');
  end;

  progress_simulate.Visible := False;
  btn_save_simulate.Enabled := True;
end;

procedure TTickerParser.PickDirectory;
var
  LSearch : TListFileSearcher;
  LFiles: TStringList;
begin
  memo_load_order.Clear;

  //now load all the files from the folder and do some work
  LFiles := TStringList.Create;
  LSearch := TListFileSearcher.Create(LFiles);
  try
    try
      LSearch.Search(edit_directory.Text, '', False);
      LoadFiles(LFiles);
      memo_load_order.Lines.Assign(LFiles);
      Application.ProcessMessages;
    finally
      LFiles.Free;
      LSearch.Free;
    end;
  except on E : Exception do
    ShowMessage(E.Message);
  end;
end;

procedure TTickerParser.btn_loadClick(Sender: TObject);
begin
  PickDirectory;
  ShowMessage('Finished Loading');
end;

procedure TTickerParser.btn_cance_simulateClick(Sender: TObject);
begin
  FCancelSim := True;
end;

procedure TTickerParser.btn_edit_strategyClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to Pred(FStrategyList.Count) do
    if FStrategyList[I].Checked then
      ConfigureNewStrategy(FStrategyList[I].Caption, FStrategies[FStrategyList[I].Tag]);
end;

procedure TTickerParser.btn_add_strategyClick(Sender: TObject);
begin
  ConfigureNewStrategy;
end;

procedure TTickerParser.LoadFiles(const AFiles: TStrings;
  const ADecimation: Single);
var
  LFile: TStringList;
  LTicker: TTickerLoader;
  I, J, LTotSkipped, LCurSkip: Integer;
  LDecimation : Single;
  LSkip: Int64;
begin
  FTickers.Clear;

  LFile := TStringList.Create;
  try
    //iterate files and load the contents
    for I := 0 to Pred(AFiles.Count) do
    begin
      if not FileExists(AFiles[I]) then
        Continue;

      LFile.LoadFromFile(AFiles[I]);

      //tickers are stored one line at a time in a json object
      for J := 0 to Pred(LFile.Count) do
      begin
        if (LFile[J].Length < 1) or (LFile[J][1] <> '{') then
          Continue;

        //load the ticker
        LTicker := TTickerLoader.Create;
        FTickers.Add(LTicker);
        LTicker.Load(LFile[J]);
      end;
    end;

    //determine if we need to decimate to a more workable amount of tickers
    if (ADecimation > 0) and (ADecimation <= 1) then
      LDecimation := ADecimation
    else
      LDecimation := DecimationPercent;

    if (LDecimation > 0) and (FTickers.Count > 1) then
    begin
      LSkip := Round(FTickers.Count / ((1 - LDecimation) * FTickers.Count));
      J := 0;

      //count of total
      LTotSkipped := 0;
      LCurSkip := 0;

      //todo - this is currently unbalanced in that all values are decimated from
      //       the beginning of the files, which isn't super accurate, although
      //       this may be fine since the beginning normally strategies aren't ready yet

      //always add the first ticker
      for I := 1 to Pred(FTickers.Count) do
      begin
        //if the current skip counter equals the number to skip, swap places
        if LCurSkip >= LSkip then
        begin
          //reset the counter
          LCurSkip := 0;

          //increment swap index
          Inc(J);

          //increment total
          Inc(LTotSkipped);

          //swap the current index with the swap index
          FTickers.Exchange(I, J);
        end;

        //current skip count
        Inc(LCurSkip);

        //if we have satisfied the decimation percent, then bail
        if LTotSkipped >= ((1 - LDecimation) * FTickers.Count) then
          Break;
      end;

      //in reverse order, delete until we make it one above the last kept index
      for I := Pred(FTickers.Count) downto Succ(J) do
        FTickers.Delete(Pred(FTickers.Count));
    end;
  finally
    LFile.Free;
  end;
end;

{ TTickerLoader }

function TTickerLoader.GetJSON: String;
begin
  Result := FJSON;
end;

function TTickerLoader.GetIsBuy: Boolean;
begin
  Result := FIsBuy;
end;

function TTickerLoader.GetIsSell: Boolean;
begin
  Result := FIsSell;
end;

procedure TTickerLoader.SetIsBuy(const AValue: Boolean);
begin
  FIsBuy := AValue;
end;

procedure TTickerLoader.SetIsSell(const AValue: Boolean);
begin
  FIsSell := AValue;
end;

procedure TTickerLoader.Load(const AJSON: String);
var
  LError: string;
begin
  if not DoLoadFromJSON(AJSON, LError) then
    Raise Exception.Create(LError);

  FJSON := AJSON;
end;

constructor TTickerLoader.Create;
begin
  inherited Create;
  FIsSell := False;
  FIsBuy := False;
  FAAC := 0;
  FInv := 0;
  FFunds := 0;
  FProf := 0;
end;

end.

