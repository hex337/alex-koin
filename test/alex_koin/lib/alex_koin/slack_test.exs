defmodule AlexKoin.SlackTest do
  use AlexKoin.DataCase
  alias AlexKoin.SlackRtm

  import Mock

  @koin_bot_id Application.get_env(:alex_koin, :koin_bot_id)

  describe "handle_event" do
    setup_with_mocks [{Slack.Sends, [], [send_raw: fn _json, _slack -> :ok end]}], context do
      channel = Map.get(context, :channel, "#general")
      timestamp = Map.get(context, :timestamp, "some thread thingy")
      prefix_bot_id = if Map.get(context, :prefix_bot_id, false), do: "<@#{@koin_bot_id}>", else: ""
      request_text =
        [prefix_bot_id, Map.get(context, :request_text, "Some message text")]
        |> Enum.join(" ")


      request_message =%{
        type: Map.get(context, :message_type, "message"),
        text: request_text,
        user: Map.get(context, :user_id, "1234"),
        ts: timestamp,
        channel: channel
      }

      response = %{
        type: "message",
        thread_ts: timestamp,
        text: Map.get(context, :response_text),
        channel: channel
      }

      response_json = response |> Poison.encode!()

      %{
        slack_message: request_message,
        response: response,
        response_json: response_json
      }
    end

    @tag request_text: "<@UC37P4L3Y> my balance"
    test "does not respond to balance messages when user ", %{slack_message: slack_message} do
      assert SlackRtm.handle_event(slack_message, %{users: %{}, ims: %{}}, %{}) == {:ok, %{}}

      assert_not_called  Slack.Sends.send_raw(:_, :_)
    end

    @tag prefix_bot_id: true,
         request_text: "my balance",
         response_text: "You have 0.0 :akc:."
    test "responds to balance messages with tagged ", %{slack_message: slack_message, response_json: response_json} do
      assert SlackRtm.handle_event(slack_message, %{users: %{}, ims: %{}}, %{}) == {:ok, %{}}

      assert_called Slack.Sends.send_raw(response_json, :_)
    end

    @tag request_text: "my balance",
         response_text: "You have 0.0 :akc:.",
         channel: "#bot-listener-channel"
    test "responds to balance messages without if you are in the right channel",
         %{slack_message: slack_message, response_json: response_json} do
      assert SlackRtm.handle_event(slack_message, %{users: %{}, ims: %{}}, %{}) == {:ok, %{}}

      assert_called  Slack.Sends.send_raw(response_json, :_)
    end

    @tag request_text: "balance for <@U12345>",
         channel: "#bot-listener-channel",
         response_text: "test name has 0.0 :akc:"
    test "responds to balance inquiries for others", %{slack_message: slack_message, response_json: response_json} do
      users = %{
        "U12345" => %{
          profile: %{
            first_name: "test",
            last_name: "name",
            email: "test@test.com",
            display_name: "test name"
          }
        }
      }

      assert SlackRtm.handle_event(slack_message, %{users: users}, %{})

      assert_called  Slack.Sends.send_raw(response_json, :_)
    end

    @tag request_text: "create koin <@U12345> for thingy",
         channel: "#bot-listener-channel"
    test "responds to create messages for <@U12345> in listener channel without koin_bot_id",
         %{slack_message: slack_message} do
      assert SlackRtm.handle_event(slack_message, %{users: %{}, ims: %{}}, %{}) == {:ok, %{}}

      assert_called Slack.Sends.send_raw(
        :meck.is(fn json ->
          String.match?(
            json,
            ~r/\{"type":"message","thread_ts":"some thread thingy","text":"Created a new koin: \`[a-z0-9\-]{36}\` with origin: 'thingy'","channel":"#bot-listener-channel"\}/
          )
        end),
        :_
      )
    end

    @tag prefix_bot_id: true,
         request_text: "create koin <@U12345> for thingy",
         channel: "#bot-listener-channel"
    test "responds to create messages for <@U12345> with koin_bot_id tag", %{slack_message: slack_message} do
      assert SlackRtm.handle_event(slack_message, %{users: %{}, ims: %{}}, %{}) == {:ok, %{}}

      assert_called Slack.Sends.send_raw(
        :meck.is(fn json ->
          String.match?(
            json,
            ~r/\{"type":"message","thread_ts":"some thread thingy","text":"Created a new koin: \`[a-z0-9\-]{36}\` with origin: 'thingy'","channel":"#bot-listener-channel"\}/
          )
        end),
        :_
      )
    end

    @tag request_text: "transfer 10 to <@U123457> memo here",
         response_text: "Not enough koin to do that transfer.",
         channel: "#bot-listener-channel"
    test "responds to transfer messages when you don't have enough balance",
         %{slack_message: slack_message, response_json: response_json} do
      assert SlackRtm.handle_event(slack_message, %{users: %{}, ims: %{}}, %{}) == {:ok, %{}}

      assert_called Slack.Sends.send_raw(response_json, :_)
    end

    @tag prefix_bot_id: true,
         request_text: "transfer 1 to <@U123457>",
         response_text: "Error: Transfer format is 'transfer [koin amount: integer] to @user [memo here]'"
    test "responds to an invalid transfer with info", %{slack_message: slack_message, response_json: response_json} do
      assert SlackRtm.handle_event(slack_message, %{users: %{}, ims: %{}}, %{}) == {:ok, %{}}

      assert_called Slack.Sends.send_raw(response_json, :_)
    end
  end
end
