import {
  CloudWatchLogsClient,
  FilterLogEventsCommand,
  FilterLogEventsCommandInput,
  FilterLogEventsResponse,
  FilteredLogEvent,
} from "@aws-sdk/client-cloudwatch-logs";

const cloudWatchClient = new CloudWatchLogsClient({ region: "eu-west-3" });

export async function fetchLogs(
  logGroupName: string,
  filterPattern: string,
  limit: number = 10
): Promise<FilteredLogEvent[]> {
  try {
    let filterInput: FilterLogEventsCommandInput = {
      logGroupName,
      filterPattern,
      limit,
    };

    console.info("Retrieving logs from AWS CloudWatch");

    let response: FilterLogEventsResponse = await cloudWatchClient.send(
      new FilterLogEventsCommand(filterInput)
    );

    return response.events!;
  } catch (error: any) {
    console.error("Error fetching log events:", error.message);
    throw error;
  }
}
