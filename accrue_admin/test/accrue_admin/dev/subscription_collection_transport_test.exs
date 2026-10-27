defmodule AccrueAdmin.Dev.SubscriptionCollectionTransportTest do
  use AccrueAdmin.LiveCase, async: false

  alias AccrueAdmin.Dev.Storybook
  alias PhoenixStorybook.StoryEntry

  @story_path "/groups/subscriptions_collection"

  test "compiled Storybook declares the production subscription collection path" do
    assert [%StoryEntry{path: @story_path}] =
             Enum.filter(Storybook.leaves(), &(&1.path == @story_path))
  end
end
