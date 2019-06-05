# ILLiadAutoFlaggingAddon

This addon will automatically add flags to requests which have not progressed in a given amount of time (similar to the way that ILLiad already applies the "Recieved?" flag to items in Request Sent). This makes it much easier to identify requests that may require extra attention.

## Configuration

The addon can be configured to watch multiple queues, with a different wait period and flag applied to each. Configuring the addon is perhaps slightly unintuitive, as ILLiad addons must contain a fixed number of settings, but the addon needs to support an arbitrary number of rules.

### Defining Rules

First, you should determine the rules that you wish to define. Each rule has four components:

1. the queue to watch
2. the request types to watch (articles, loans, or both)
3. the number of days to wait
4. the flag to apply

If you'd like to check both articles and loans within the same queue, but want to wait a different number of days, or apply a different flag, then you should define two separate rules for the same queue.

Also, please note that all flags must be defines in the ILLiad Customization Manager before the addon can apply them (System > Custom Flags > CustomFlags).

### Configuring Addon Settings

Once you've worked out all of your rules, you're ready to convert them into addon settings strings.

- WatchQueues should be a comma-separated list of each queue that you want to watch.
- RequestTypes should be a comma-separated list of the request type that you want to watch in each of the queues defined in WatchQueues. These values must be single letters (A for articles, L for loans, B for both).
- DaysToWait should be a comma-separated list of integers, each defining the number of days to wait before flagging requests in each queue.
- WatchFlags should be a comma-separated list of flag names to apply.

Each setting must have the same number of entries defined, or the addon will not run. Do not include extraneous spaces, quotes, or other punctuation that do not appear in the actual names of the flags and queues listed.

## Usage

The addon will run whenever your System Manager addon interval elapses (defined in the Customization Manager at System > General > SystemManagerAddonInterval).

If a flag is removed from a request, but the request's TransactionDate is not updated, then the addon will re-add the flag; if you want to avoid this, you'll need to route the request (even routing it to the same queue will update the TransactionDate).









