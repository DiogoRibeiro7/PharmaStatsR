const { test, expect } = require('@playwright/test');
const { AxeBuilder } = require('@axe-core/playwright');

// Four subjects, three visits, with nonzero subject and residual variation.
const validCSV = 'SubjectID,Time,DV\n' + [-3, -1, 1, 3].flatMap((offset, i) =>
  [-1, 0, 1].map((time, j) => `${i + 1},${time},${2 + 1.5 * time + offset + [1, -2, 1][j]}`)
).join('\n');
const upload = (page, contents, name = 'example.csv') => page.getByLabel('Upload data (.csv)').setInputFiles({
  name, mimeType: 'text/csv', buffer: Buffer.from(contents),
});
async function audit(page, testInfo, state) {
  // Shiny may retain and dim an old table while a visible output recalculates.
  // Audit the settled result, including completion of its opacity transition.
  await expect(page.locator('html')).not.toHaveClass(/shiny-busy/);
  await expect(page.locator('.recalculating:visible')).toHaveCount(0);
  for (const output of await page.locator('.shiny-bound-output:visible').all()) {
    await expect(output).toHaveCSS('opacity', '1');
  }
  const results = await new AxeBuilder({ page }).analyze();
  await testInfo.attach(`axe-${state}`, { body: JSON.stringify(results, null, 2), contentType: 'application/json' });
  expect(results.violations, `axe violations in ${state}`).toEqual([]);
}
async function fit(page) {
  await page.getByRole('spinbutton', { name: 'Time bins' }).fill('2');
  await page.getByRole('spinbutton', { name: 'Time bins' }).press('Tab');
  await upload(page, validCSV);
  await expect(page.locator('#status')).toHaveText("Data loaded. Click 'Fit model' to enable diagnostics.");
  await page.getByRole('button', { name: 'Fit model', exact: true }).press('Enter');
  await expect(page.locator('#status')).toHaveText('Model ready.');
  await expect(page.locator('#source_name')).toHaveText('Data source: example.csv');
  await expect(page.getByRole('status', { name: 'File upload status', exact: true })).toHaveText('Upload complete');
  await expect(page.locator('#obs_pred img')).toBeVisible();
}

test.beforeEach(async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('#status')).toHaveText('No data loaded.');
});

test('keyboard upload, fitting, tabs and numerical alternatives', async ({ page }, testInfo) => {
  await expect(page.locator('html')).toHaveAttribute('lang', 'en');
  await expect(page.getByRole('heading', { level: 1 })).toHaveText('PharmaStatsR Diagnostics');
  await expect(page.getByRole('main', { name: 'Diagnostics', exact: true })).toBeVisible();
  await expect(page.getByRole('status', { name: 'Model status' })).toHaveAttribute('aria-atomic', 'true');
  await audit(page, testInfo, 'empty');
  await page.keyboard.press('Tab');
  await expect(page.getByRole('link', { name: 'Skip to diagnostics' })).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page.getByRole('main', { name: 'Diagnostics', exact: true })).toBeFocused();
  // Reverse through the controls from the skip target. Reloading a URL with
  // its fragment can restore focus differently across browser/platform pairs.
  await page.keyboard.press('Shift+Tab');
  await expect(page.getByRole('button', { name: 'Fit model', exact: true })).toBeFocused();
  await page.keyboard.press('Shift+Tab');
  await expect(page.getByRole('spinbutton', { name: 'Time bins' })).toBeFocused();
  await page.keyboard.press('Shift+Tab');
  const chooser = page.getByLabel('Upload data (.csv)');
  await expect(chooser).toBeFocused();
  const box = await chooser.boundingBox();
  expect(box.x).toBeGreaterThanOrEqual(0);
  expect(box.y).toBeGreaterThanOrEqual(0);
  expect(await chooser.evaluate(el => getComputedStyle(el).outlineStyle)).toBe('solid');
  const chosen = page.waitForEvent('filechooser');
  await page.keyboard.press('Enter');
  await (await chosen).setFiles({ name: 'example.csv', mimeType: 'text/csv', buffer: Buffer.from(validCSV) });
  await expect(page.locator('#status')).toContainText('Data loaded.');
  await page.keyboard.press('Tab');
  await expect(page.getByRole('spinbutton', { name: 'Time bins' })).toBeFocused();
  await page.getByRole('spinbutton', { name: 'Time bins' }).fill('2');
  await page.keyboard.press('Tab');
  await expect(page.getByRole('button', { name: 'Fit model', exact: true })).toBeFocused();
  await page.keyboard.press('Enter');
  await expect(page.locator('#status')).toHaveText('Model ready.');
  await expect(page.locator('#source_name')).toHaveText('Data source: example.csv');
  await expect(page.getByRole('status', { name: 'File upload status', exact: true })).toHaveText('Upload complete');
  await expect(page.getByRole('button', { name: 'Fit model', exact: true })).toBeFocused();
  await page.keyboard.press('Tab');
  await expect(page.getByRole('tab', { name: 'Observed vs Predicted', exact: true })).toBeFocused();

  const views = [
    ['Observed vs Predicted', 'obs_pred', 'Observed and fitted responses', 12],
    ['Residuals', 'residuals', 'Raw and normalized residuals', 24],
    ['Binned summary', 'vpc', 'Observed and fitted summaries by time bin', 2],
  ];
  for (const [index, [title, id, caption, rows]] of views.entries()) {
    const tab = page.getByRole('tab', { name: title, exact: true });
    if (index) await page.keyboard.press('ArrowRight');
    await expect(tab).toBeFocused();
    await expect(tab).toHaveAttribute('aria-selected', 'true');
    await expect(page.locator(`#${id} img`)).toHaveAttribute('alt', /Numerical data|numerical data/);
    await page.keyboard.press('Tab'); // tab panel
    await page.keyboard.press('Tab'); // native details summary
    const disclosure = page.locator('summary').filter({ hasText: `View numerical data: ${title}` });
    await expect(disclosure).toBeFocused();
    await page.keyboard.press('Space');
    const table = page.getByRole('table', { name: caption, exact: true });
    await expect(table).toBeVisible();
    await expect(table.locator('tbody tr')).toHaveCount(rows);
    for (const header of await table.getByRole('columnheader').all()) await expect(header).toHaveAttribute('scope', 'col');
    await page.keyboard.press('Tab');
    await expect(page.getByRole('region', { name: `${title} data table`, exact: true })).toBeFocused();
    await audit(page, testInfo, id);
    await page.keyboard.press('Shift+Tab');
    await page.keyboard.press('Shift+Tab');
    await page.keyboard.press('Shift+Tab');
    await expect(tab).toBeFocused();
  }
  await page.screenshot({ path: testInfo.outputPath('binned-summary.png'), fullPage: true });
});

test('invalid input clears stale values and recovers without moving focus', async ({ page }, testInfo) => {
  await fit(page);
  await page.getByRole('tab', { name: 'Binned summary', exact: true }).click();
  await page.locator('summary').filter({ hasText: 'View numerical data: Binned summary' }).press('Enter');
  const bins = page.getByRole('spinbutton', { name: 'Time bins' });
  await bins.fill('1');
  await bins.press('Tab');
  await expect(page.locator('#bins_feedback')).toHaveText('Choose a whole number of time bins (at least 2).');
  await expect(page.locator('#vpc img')).toHaveCount(0);
  await expect(page.locator('#vpc_data table')).toHaveCount(0);
  await expect(page.locator('#status')).toHaveText('Model ready.');
  await expect(page.locator('#source_name')).toHaveText('Data source: example.csv');
  await expect(page.getByRole('status', { name: 'File upload status', exact: true })).toHaveText('Upload complete');
  await audit(page, testInfo, 'invalid-bins');
  await bins.fill('2');
  await bins.press('Tab');
  await expect(page.locator('#vpc_data table')).toBeVisible();
  await expect(page.locator('#bins_feedback')).toBeEmpty();
  await upload(page, 'SubjectID,Time\n1,0\n', 'invalid.csv');
  await expect(page.locator('#status')).toContainText('Upload failed: Missing required columns: DV');
  await expect(page.locator('#source_name')).toBeEmpty();
  await expect(page.locator('#vpc img')).toHaveCount(0);
  await expect(page.locator('#vpc_data table')).toHaveCount(0);
  await audit(page, testInfo, 'invalid-upload');
  await upload(page, validCSV.replace(/,-?[0-9.]+(?=\n|$)/g, ',1'), 'constant.csv');
  await expect(page.locator('#status')).toContainText('Data loaded.');
  await page.getByRole('button', { name: 'Fit model', exact: true }).press('Enter');
  await expect(page.locator('#status')).toContainText('Fit failed:');
  await expect(page.locator('#vpc_data table')).toHaveCount(0);
  await audit(page, testInfo, 'failed-fit');
  await page.getByRole('tab', { name: 'Observed vs Predicted', exact: true }).click();
  await fit(page);
  await page.locator('summary').filter({ hasText: 'View numerical data: Observed vs Predicted' }).press('Enter');
  await expect(page.locator('#obs_pred_data tbody tr')).toHaveCount(12);
  await audit(page, testInfo, 'recovered');
});


test('narrow viewport keeps controls and table scrolling reachable', async ({ page }, testInfo) => {
  await page.setViewportSize({ width: 320, height: 800 });
  await fit(page);
  await page.locator('summary').filter({ hasText: 'View numerical data: Observed vs Predicted' }).press('Enter');
  const region = page.getByRole('region', { name: 'Observed vs Predicted data table', exact: true });
  await region.focus();
  await page.keyboard.press('ArrowDown');
  await expect.poll(() => region.evaluate(el => el.scrollTop)).toBeGreaterThan(0);
  expect(await page.evaluate(() => document.documentElement.scrollWidth)).toBeLessThanOrEqual(320);
  await audit(page, testInfo, 'narrow-viewport');
  await page.screenshot({ path: testInfo.outputPath('narrow-viewport.png'), fullPage: true });
});


test('transport errors remain visible in the upload live region', async ({ page }, testInfo) => {
  await page.getByLabel('Upload data (.csv)').setInputFiles({
    name: 'too-large.csv', mimeType: 'text/csv', buffer: Buffer.alloc(6 * 1024 * 1024, 'x'),
  });
  const uploadStatus = page.getByRole('status', { name: 'File upload status', exact: true });
  await expect(uploadStatus).toContainText('Maximum upload size exceeded');
  await expect(uploadStatus).toHaveAttribute('aria-live', 'polite');
  await expect(page.locator('#status')).toHaveText('No data loaded.');
  await audit(page, testInfo, 'upload-size-error');
  await fit(page);
});
