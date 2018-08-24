defmodule AlexKoin.SlackTest do
  use AlexKoin.DataCase
  alias AlexKoin.SlackRtm

  describe "handle_event" do
    setup do
      AlexKoin.Test.SlackSendStub.init()
    end

    test "responds to balance messages" do
      json = "{\"type\":\"message\",\"thread_ts\":\"some thread thingy\",\"text\":\"You have 0.0:akc:.\",\"channel\":\"some channel\"}"
      AlexKoin.Test.SlackSendStub.respond_to(:send_raw, [json, %{}], false)
      slack_message = %{
        type: "message",
        text: "<@UC37P4L3Y> my balance",
        user: "1234",
        ts: "some thread thingy",
        channel: "some channel"
      }
      assert SlackRtm.handle_event(slack_message, %{}, %{})
    end

    test "responds to create messages" do
      json = "{\"type\":\"message\",\"thread_ts\":null,\"text\":\"Created a new coin: uuid here with origin: 'thingy'\",\"channel\":\"some channel\"}"
      AlexKoin.Test.SlackSendStub.respond_to(:send_raw, [json, %{}], false)

      slack_message = %{
        type: "message",
        text: "<@UC37P4L3Y> create koin <@U12345> for thingy",
        user: "U8BBZEB35",
        ts: "some thread thingy",
        channel: "some channel"
      }

      assert SlackRtm.handle_event(slack_message, %{ims: []}, %{})
    end

    test "responds to transfer messages when you don't have enough balance" do
      json = "{\"type\":\"message\",\"thread_ts\":null,\"text\":\"You don't have enough koin to do that transfer.\",\"channel\":\"D123456\"}"
      AlexKoin.Test.SlackSendStub.respond_to(:send_raw, [json, %{}], false)

      slack_message = %{
        type: "message",
        text: "transfer 10 to <@U123457> memo here",
        user: "U123456",
        ts: "timestamp",
        channel: "D123456"
      }

      assert SlackRtm.handle_event(slack_message, %{}, %{})
    end

    test "responds to an invalid transfer with info" do
      json = "{\"type\":\"message\",\"thread_ts\":null,\"text\":\"Error: Transfer format is 'transfer [koin amount: integer] to @user [memo here]'\",\"channel\":\"D123456\"}"
      AlexKoin.Test.SlackSendStub.respond_to(:send_raw, [json, %{}], false)

      slack_message = %{
        type: "message",
        text: "transfer 1 to <@U123457>",
        user: "U123456",
        ts: "timestamp",
        channel: "D123456"
      }

      assert SlackRtm.handle_event(slack_message, %{}, %{})
    end
  end

end
