defmodule JollaCNBot.Connection.RabbitMQ do
  use RBMQ.Connection,
    otp_app: :jollacn_bot

  # Optionally you can define queue params right here,
  # but it's better to do so in producer and consumer separately
end
