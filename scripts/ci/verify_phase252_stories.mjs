export async function executeCommandSequence(commands, execute, persist) {
  const results = [];
  for (const command of commands) {
    results.push(await execute(command));
  }
  const bundle = { status: "passed", commands: results };
  await persist(bundle);
  return bundle;
}
