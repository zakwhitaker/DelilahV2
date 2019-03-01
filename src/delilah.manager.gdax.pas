unit delilah.manager.gdax;

{$mode delphi}

interface

uses
  Classes, SysUtils, delilah.types, delilah.manager, gdax.api.types,
  gdax.api.consts, fgl;

type

  { IGDAXOrderManager }
  (*
    order manager for the GDAX crypto currency exchange
  *)
  IGDAXOrderManager = interface(IOrderManager)
    ['{0F58D00E-7D26-447B-B246-C70AE651670C}']
    //property methods
    function GetAuth: IGDAXAuthenticator;
    procedure SetAuth(Const AValue: IGDAXAuthenticator);
    //properties
    property Authenticator : IGDAXAuthenticator read GetAuth write SetAuth;
  end;

  { TGDAXOrderManagerImpl }
  (*
    base implementation of a gdax order manager
  *)
  TGDAXOrderManagerImpl = class(TOrderManagerImpl,IGDAXOrderManager)
  strict private
    FAuth: IGDAXAuthenticator;
    FSettleMap: TFPGMap<String,Integer>;
    function GetAuth: IGDAXAuthenticator;
    procedure SetAuth(Const AValue: IGDAXAuthenticator);
    function SettleCountCheck(Const AID:String):Boolean;

    const
      MAX_SETTLE_COUNT = 10;
  strict protected
    function GDAXDetailsValid(Const ADetails:IOrderDetails;Out Error:String):Boolean;
    function GDAXStatusToEngineStatus(Const AStatus:TOrderStatus):TOrderManagerStatus;
    function DoPlace(const ADetails: IOrderDetails;
      out Error: String): Boolean; override;
    function DoCancel(const ADetails: IOrderDetails;
      out Error: String): Boolean; override;
    function DoGetStatus(const ADetails: IOrderDetails): TOrderManagerStatus;override;
    function DoRefresh(out Error: String): Boolean; override;
  public
    property Authenticator : IGDAXAuthenticator read GetAuth write SetAuth;
    constructor Create; override;
    destructor Destroy; override;
  end;

implementation
uses
  gdax.api.authenticator, delilah.order.gdax, gdax.api.fills, math;

{ TGDAXOrderManagerImpl }

function TGDAXOrderManagerImpl.GetAuth: IGDAXAuthenticator;
begin
  Result:=FAuth;
end;

procedure TGDAXOrderManagerImpl.SetAuth(const AValue: IGDAXAuthenticator);
begin
  FAuth:=nil;
  FAuth:=AValue;
end;

function TGDAXOrderManagerImpl.SettleCountCheck(const AID: String): Boolean;
var
  I, LCount: Integer;
begin
  Result:=False;
  I:=FSettleMap.IndexOf(AID);
  LCount:=0;

  //if the id doesn't exist, then we aren't tracking and we need to
  if I < 0 then
  begin
    FSettleMap.Add(AID,LCount);
    Exit;
  end;

  //fetch the count from the map
  LCount:=FSettleMap[AID];

  //shouldn't happen, just do this for safety
  if LCount < 0 then
    LCount:=0;

  //check to see if this would count for hitting the max count
  if Succ(LCount) >= MAX_SETTLE_COUNT then
  begin
    //cleanup tracked id
    FSettleMap.Delete(I);
    Exit(True);
  end
  else
  begin
    Inc(LCount);
    FSettleMap.AddOrSetData(AID,LCount);
  end;
end;

function TGDAXOrderManagerImpl.GDAXDetailsValid(const ADetails: IOrderDetails;
  out Error: String): Boolean;
var
  LDetails:IGDAXOrderDetails;
begin
  Result:=False;
  if not Assigned(ADetails) then
  begin
    Error:='order details nil or invalid';
    Exit;
  end;
  if not (ADetails is IGDAXOrderDetails) then
  begin
    Error:='order details is not IGDAXOrderDetails';
    Exit;
  end;
  LDetails:=ADetails as IGDAXOrderDetails;
  if not Assigned(LDetails.Order) then
  begin
    Error:='gdax not assigned in order details';
    Exit;
  end;
  Result:=True;
end;

function TGDAXOrderManagerImpl.GDAXStatusToEngineStatus(
  const AStatus: TOrderStatus): TOrderManagerStatus;
begin
  Result:=omCanceled;
  //map the gdax status as best we can to the engine statuses
  case AStatus of
    stActive,stPending,stOpen: Result:=omActive;
    stCancelled,stRejected,stUnknown: Result:=omCanceled;
    stDone,stSettled: Result:=omCompleted;
  end;
end;

function TGDAXOrderManagerImpl.DoPlace(const ADetails: IOrderDetails;
  out Error: String): Boolean;
var
  LDetails:IGDAXOrderDetails;
  LContent:String;
begin
  Result:=False;
  try
    //will check everything needed for continuing
    if not GDAXDetailsValid(ADetails,Error) then
      Exit;
    LDetails:=ADetails as IGDAXOrderDetails;
    LDetails.Order.Authenticator:=Authenticator;

    //do rounding here for the size to avoid too accurate errors
    LDetails.Order.Size:=RoundTo(LDetails.Order.Size,-8);

    //attempt to post the order assuming strategy has filled it out correctly
    if not LDetails.Order.Post(LContent,Error) then
    begin
      LogInfo('post body: ' + LDetails.Order.PostBody);

      //this code is in place because I believe coinbase doesn't
      //respect their quote_increment setting 100% correctly... saw it with
      //bat-usdc, anyways in this case try a truncated version
      if Error.IndexOf('too accurate') > 0 then
      begin
        //set the size to as many min sizes fit in the requested size
        LDetails.Size:=Trunc(LDetails.Size / LDetails.Order.Product.BaseMinSize) * LDetails.Order.Product.BaseMinSize;

        //attempt one more post
        if not LDetails.Order.Post(LContent,Error) then
          Exit;
      end
      else
        Exit;
    end;

    if LDetails.Order.OrderStatus in [stCancelled,stUnknown,stRejected] then
    begin
      Error:=LDetails.Order.RejectReason;
      Exit;
    end;
    Result:=True;
  except on E:Exception do
    Error:=E.Message;
  end;
end;

function TGDAXOrderManagerImpl.DoCancel(const ADetails: IOrderDetails;
  out Error: String): Boolean;
var
  I:Integer;
  LDetails:IGDAXOrderDetails;
  LFills:IGDAXFills;
  LContent,
  LID:String;
begin
  Result:=False;
  try
    //will check everything needed for continuing
    if not GDAXDetailsValid(ADetails,Error) then
      Exit;
    LDetails:=ADetails as IGDAXOrderDetails;
    LDetails.Order.Authenticator:=Authenticator;

    LogInfo(Format('DoCancel::starting cancel [OrderID]-%s',[LDetails.Order.ID]));

    //attempt to delete the order assuming strategy has filled it out correctly
    if not LDetails.Order.Delete(LContent,Error) then
    begin
      LogError('DoCancel::Delete::failure with [Content]-'+LContent);
      Exit;
    end;

    //the order has been cancelled, so update the status
    LDetails.Order.OrderStatus:=stCancelled;

    //in the event of partial fills, we need to check if the fills
    //object returns anything, if so, we need to update the cancelled
    //order's properties (since cancelling an empty order removes the id
    //entirely from gdax)
    LFills:=TGDAXFillsImpl.Create;
    LFills.OrderID:=LID;
    LFills.Authenticator:=FAuth;
    if not LFills.Get(LContent,Error) then
    begin
      LogInfo(
        Format(
          'DoCancel::FillsCheck::fills check failed but may be fine if not ' +
          'a partial, [Error]-%s [Content]-%s',
          [Error,LContent]
        )
      );

      //in this case try to fall back to an order check just to make sure
      //something with fills isn't going wrong
      if not LDetails.Order.Get(LContent,Error) then
      begin
        LogInfo(
          Format(
            'DoCancel::OrderCheckFallback::order check failed but may be fine if not ' +
            'a partial, [Error]-%s [Content]-%s',
            [Error,LContent]
          )
        );
      end;
    end;

    //check if we have partial fills by looking at the count
    if LFills.Count > 0 then
    begin
      //update size and fees with our fills object
      LDetails.Order.FilledSized:=LFills.TotalSize[[]];
      LDetails.Order.FillFees:=LFills.TotalFees[[]];

      //log that we had a partial fill
      LogInfo(
        Format(
          'DoCancel::PartialFound::[FilledSize]-%s [FillFees]-%s',
          [
            FloatToStr(LDetails.Order.FilledSized),
            FloatToStr(LDetails.Order.FillFees)
          ]
        )
      );

      //manually fill out the executed value property (cumulative size * price) / size
      for I:=0 to Pred(LFills.Count) do
        LDetails.Order.ExecutedValue:=LDetails.Order.ExecutedValue + LFills.Entries[I].Size * LFills.Entries[I].Price;
      LDetails.Order.ExecutedValue:=LDetails.Order.ExecutedValue / LFills.TotalSize[[]];
    end;

    Result:=True;
  except on E:Exception do
    Error:=E.Message;
  end;
end;

function TGDAXOrderManagerImpl.DoGetStatus(const ADetails: IOrderDetails): TOrderManagerStatus;
var
  LDetails:IGDAXOrderDetails;
  LOldStatus:TOrderManagerStatus;
  LID:String;
  LContent:String;
  LError:String;
begin
  Result:=omCanceled;
  try
    //will check everything needed for continuing
    if not GDAXDetailsValid(ADetails,LError) then
    begin
      LogError('DoGetStatus::[Error]-' + LError);
      Exit;
    end;

    LDetails:=ADetails as IGDAXOrderDetails;
    LOldStatus:=GDAXStatusToEngineStatus(LDetails.Order.OrderStatus);
    LDetails.Order.Authenticator:=Authenticator;

    //avoid a web call for cancelled orders
    if LDetails.Order.OrderStatus <> stCancelled then
    begin
      //just dump the order info to make debugging logs easier
      LogInfo('DoGetStatus::OrderInfo::' + LDetails.Order.PostBody);

      //attempt to get the order assuming strategy has filled it out correctly
      if not LDetails.Order.Get(LContent,LError) then
      begin
        LogError('DoGetStatus::' + LError);
        Exit;
      end
      else
        LogInfo('DoGetStatus::' + LContent);

      if not ID(ADetails,LID) then
      begin
        LError:='unable to fetch id for order details in ' + Self.Classname;
        LogError('DoGetStatus::' + LError);
        Exit;
      end;
      Result:=GDAXStatusToEngineStatus(LDetails.Order.OrderStatus);

      //during the GDAX order life-cycle, there is a small window of time
      //before the order is marked as done, and finally marked as settled.
      //this check is in place to account for that, so we don't mark an order
      //complete prematurely
      if Result=omCompleted then
        if not LDetails.Order.Settled then
        begin
          //old status is used for status updates, always set this to active
          //in the case it is reported incorrectly as "completed"
          if LOldStatus = omCompleted then
            LOldStatus:=omActive;

          //will check against max tries for settle count and return true if so
          if not SettleCountCheck(LDetails.Order.ID) then
            Result:=omActive
          else
            Result:=omCompleted;
        end
        //cleanup if we have stored in settle map
        else if FSettleMap.IndexOf(LDetails.Order.ID) >= 0 then
          FSettleMap.Delete(FSettleMap.IndexOf(LDetails.Order.ID));
    end
    else
      Result:=omCompleted;

    //notify listeners since base class does not handle status changes when
    //fetching statuses (handles cancel, remove, place automatically)
    if LOldStatus<>Result then
      DoOnStatus(LDetails,LID,LOldStatus,Result);
  except on E:Exception do
  begin
    LError:=E.Message;
    LogError('DoGetStatus::' + LError);
  end
  end;
end;

function TGDAXOrderManagerImpl.DoRefresh(out Error: String): Boolean;
var
  I:Integer;
begin
  LogInfo('DoRefresh::[OrderCount]-' + IntToStr(Orders.Count));

  //right now, we will just go through the listing of orders and check
  //the status. this will count against gdax private endpoint limit, so
  //if the strategy stores a lot of orders, this may cause a problem. could
  //potentially sort by price and only refresh up to a certain price?
  Result:=False;
  try
    for I:=0 to Pred(Orders.Count) do
      Status[Orders.Keys[I]];
    Result:=True;
  except on E:Exception do
    Error:=E.Message;
  end;
end;

constructor TGDAXOrderManagerImpl.Create;
begin
  inherited Create;
  FAuth:=TGDAXAuthenticatorImpl.Create;
  FSettleMap:=TFPGMap<String,Integer>.Create;
end;

destructor TGDAXOrderManagerImpl.Destroy;
begin
  FAuth:=nil;
  FSettleMap.Free;
  inherited Destroy;
end;

end.

