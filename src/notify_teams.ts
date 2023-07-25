export async function notifyMicrosoftTeams(
  teamsWebhookUrl: string,
  messages: string[],
  redirectUri: string
): Promise<void> {
  try {
    let requestOptions: RequestInit = {
      method: "POST",
      body: JSON.stringify({
        "@type": "MessageCard",
        "@context": "http://schema.org/extensions",
        themeColor: "0076D7",
        title: "[AWS CloudWatch] An anomaly was detected",
        sections: [
          {
            activityTitle: "Error Message",
            activitySubtitle: new Date().toUTCString(),
            text: messages.join("\n"),
          },
        ],
        potentialAction: [
          {
            "@type": "ActionCard",
            name: "Visit",
            actions: [
              {
                "@type": "OpenUri",
                name: "See more",
                targets: [{ os: "default", uri: redirectUri }],
              },
            ],
          },
        ],
      }),
      headers: {
        "Content-type": "application/json; charset=UTF-8",
      },
    };

    const response = await fetch(teamsWebhookUrl, requestOptions);

    console.info("Microsoft Teams response:", response.text.toString());
  } catch (error: any) {
    console.error("Failed to notify Microsoft Teams:", error.message);
    throw error;
  }
}
