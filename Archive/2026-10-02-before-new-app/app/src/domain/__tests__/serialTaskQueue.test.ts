import { SerialTaskQueue } from '../../purchases/serialTaskQueue';

describe('SerialTaskQueue', () => {
  it('runs billing tasks one at a time in submission order', async () => {
    const queue = new SerialTaskQueue();
    const events: string[] = [];
    let activeTasks = 0;
    let maximumActiveTasks = 0;

    const task = (name: string) => async () => {
      events.push(`${name}:start`);
      activeTasks += 1;
      maximumActiveTasks = Math.max(maximumActiveTasks, activeTasks);
      await Promise.resolve();
      activeTasks -= 1;
      events.push(`${name}:finish`);
      return name;
    };

    const results = await Promise.all([
      queue.run(task('lifetime')),
      queue.run(task('monthly')),
      queue.run(task('ownership')),
    ]);

    expect(results).toEqual(['lifetime', 'monthly', 'ownership']);
    expect(maximumActiveTasks).toBe(1);
    expect(events).toEqual([
      'lifetime:start',
      'lifetime:finish',
      'monthly:start',
      'monthly:finish',
      'ownership:start',
      'ownership:finish',
    ]);
  });

  it('continues after a failed billing task', async () => {
    const queue = new SerialTaskQueue();
    const failed = queue.run(async () => {
      throw new Error('query failed');
    });
    const recovered = queue.run(async () => 'recovered');

    await expect(failed).rejects.toThrow('query failed');
    await expect(recovered).resolves.toBe('recovered');
  });
});
