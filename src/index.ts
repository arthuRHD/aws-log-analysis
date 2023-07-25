import { FilteredLogEvent } from "@aws-sdk/client-cloudwatch-logs";
import { Handler } from "aws-lambda";
import { notifyMicrosoftTeams } from "./notify_teams";
import { fetchLogs } from "./fetch_logs";

const logGroupName: string = "error-log";
const filterPattern: string = "ERROR";
const teamsWebhookUrl: string = "https://teams-webhook.com";

export const handler: Handler = async () => {
  try {
    let logEvents: FilteredLogEvent[] = await fetchLogs(
      logGroupName,
      filterPattern
    );

    if (logEvents && logEvents.length > 0) {
      await notifyMicrosoftTeams(
        teamsWebhookUrl,
        logEvents.map((logEvent) => logEvent.message!),
        "https://google.fr"
      );
    } else {
      console.info("No logs were found.");
    }
  } catch (error: any) {
    console.error("Error processing log events:", error.message);
    throw error;
  }
};
