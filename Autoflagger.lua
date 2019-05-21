-- Autoflagger Addon
-- Austin Smith, University of Maryland Libraries
--
-- This addon automatically adds flags to items in designated queues which have
-- not been updated recently. The list of queues to watch, days to wait before
-- flagging, and flags to add are all configured via addon settings. All flags
-- must additionally be added via the Customization Manager.

luanet.load_assembly("System.Data");
local types = {};
types["SqlDbType"] = luanet.import_type("System.Data.SqlDbType");

local Settings = {};
Settings.WatchQueues = {};
Settings.RequestTypes = {};
Settings.DaysToWait = {};
Settings.WatchFlags = {};

LogDebug("Auoflagger - Parsing setting strings.")

-- parse comma-separated setting strings into tables
GetSetting("WatchQueues"):gsub("[^,]+", function(c) table.insert(Settings.WatchQueues, c:match "^%s*(.-)%s*$") end);
GetSetting("RequestTypes"):gsub("[^,]+", function(c) table.insert(Settings.RequestTypes, c:match "^%s*(.-)%s*$") end);
GetSetting("DaysToWait"):gsub("[^,]+", function(c) table.insert(Settings.DaysToWait, c:match "^%s*(.-)%s*$") end) ;
GetSetting("WatchFlags"):gsub("[^,]+", function(c) table.insert(Settings.WatchFlags, c:match "^%s*(.-)%s*$") end);

LogDebug("Autoflagger - Settings loaded.")
--LogDebug(dump(Settings.WatchQueues))
--LogDebug(dump(Settings.RequestTypes))
--LogDebug(dump(Settings.DaysToWait))
--LogDebug(dump(Settings.WatchFlags))

local isCurrentlyProcessing = false;

function Init()
  LogDebug("Initializing Autoflagger addon.");
	RegisterSystemEventHandler("SystemTimerElapsed", "CheckWatchQueues");
end

-- Checks each of the queues defined in the Settings, and flags requests as appropriate
function CheckWatchQueues(eventArgs)
  if isCurrentlyProcessing then return end;
  isCurrentlyProcessing = true;

  -- Make sure that the settings strings all have the same length.
  -- If not, log an error and abort.
  if not (#Settings.WatchQueues == #Settings.DaysToWait and
          #Settings.WatchQueues == #Settings.WatchFlags and
          #Settings.WatchQueues == #Settings.RequestTypes) then
    LogDebug("Autoflagger Configuration Error: Settings lists are not all of same length.");
    LogDebug("WatchQueues has " .. #Settings.WatchQueues .. "entries.")
    LogDebug("RequestTypes has " .. #Settings.RequestTypes .. "entries.")
    LogDebug("DaysToWait has " .. #Settings.DaysToWait .. "entries.")
    LogDebug("WatchFlags has " .. #Settings.WatchFlags .. "entries.")
    return;
  end

  LogDebug("Executing Autoflagger addon.")

  -- define query template and create connection
  local query_template_general = "SELECT t.TransactionNumber FROM Transactions t WHERE t.TransactionStatus = @RequestStatus AND DATEADD(dd, @Days, t.TransactionDate) < GETDATE();";
  local query_template_specific = "SELECT t.TransactionNumber FROM Transactions t WHERE t.TransactionStatus = @RequestStatus AND t.RequestType = @RequestType AND DATEADD(dd, @Days, t.TransactionDate) < GETDATE();";

  local connection;


  -- loop through the list of queues.
  for idx, queue in pairs(Settings.WatchQueues) do
    connection = CreateManagedDatabaseConnection();
    LogDebug("Adding flags to queue: "..queue);
    -- get the corresponding number of days for this queue.
    days = Settings.DaysToWait[idx];
    -- get the corresponding flag for this queue
    flag = Settings.WatchFlags[idx];

  	if Settings.RequestTypes[idx] == 'B' then
	  	query_template = query_template_general
  		connection.QueryString = query_template;
	  	connection:AddParameter('@Days', days, types.SqlDbType.Int);
  		connection:AddParameter('@RequestStatus', queue, types.SqlDbType.VarChar);
    else
	  	connection.QueryString = query_template_specific;
  		connection:AddParameter('@Days', days, types.SqlDbType.Int);
	  	connection:AddParameter('@RequestStatus', queue, types.SqlDbType.VarChar);
  		if Settings.RequestTypes[idx] == 'A' then
	  		connection:AddParameter('@RequestType', 'Article', types.SqlDbType.VarChar);
  		elseif Settings.RequestTypes[idx] == 'L' then
	  		connection:AddParameter('@RequestType', 'Loan', types.SqlDbType.VarChar);
		  end
	  end

	  LogDebug(connection.QueryString);
    local transactions = connection:Execute();

    -- Loop through results, flagging each transaction.
    for i = 0, transactions.Rows.Count - 1 do
      local tn = transactions.Rows:get_Item(i):get_Item(0)
      --LogDebug("Adding " .. flag .. " Flag to TN " .. tn)
      ExecuteCommand("AddTransactionFlag", {tn, flag});
    end
    connection:Dispose();
  end


  isCurrentlyProcessing = false;
end
