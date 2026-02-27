const fs = require('fs');

const EXPECTED_VARK_MODES = ['visual', 'aural', 'readwrite', 'kinesthetic'];
const EXPECTED_LEVELS = ['foundation', 'build', 'compete', 'maintain'];
const EXPECTED_LENGTHS = ['micro', 'standard', 'deep'];

function safeString(value, fallback = '') {
  if (value == null) return fallback;
  return String(value).trim();
}

function parseCsvContent(content) {
  if (!content || typeof content !== 'string') {
    return [];
  }

  const rows = [];
  let currentField = '';
  let currentRow = [];
  let inQuotes = false;
  const raw = content.replace(/^\uFEFF/, '');

  const pushField = () => {
    currentRow.push(currentField);
    currentField = '';
  };

  const pushRow = () => {
    const hasValues = currentRow.some((value) => safeString(value).length > 0);
    if (hasValues) {
      rows.push(currentRow);
    }
    currentRow = [];
  };

  for (let i = 0; i < raw.length; i += 1) {
    const char = raw[i];
    const nextChar = raw[i + 1];

    if (char === '"') {
      if (inQuotes && nextChar === '"') {
        currentField += '"';
        i += 1;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (char === ',' && !inQuotes) {
      pushField();
      continue;
    }

    if ((char === '\n' || char === '\r') && !inQuotes) {
      if (char === '\r' && nextChar === '\n') {
        i += 1;
      }
      pushField();
      pushRow();
      continue;
    }

    currentField += char;
  }

  pushField();
  pushRow();

  if (rows.length === 0) {
    return [];
  }

  const headers = rows[0].map((header) => safeString(header));
  const output = [];

  for (let i = 1; i < rows.length; i += 1) {
    const row = rows[i];
    if (!row || row.length === 0) {
      continue;
    }

    if (row.length > headers.length) {
      const overflow = row.slice(headers.length - 1).join(',');
      row.splice(headers.length - 1, row.length - headers.length + 1, overflow);
    }

    if (row.length < headers.length) {
      for (let j = row.length; j < headers.length; j += 1) {
        row.push('');
      }
    }

    const mapped = {};
    headers.forEach((header, index) => {
      mapped[header] = safeString(row[index]);
    });
    output.push(mapped);
  }

  return output;
}

function parseCsvFile(filePath) {
  const raw = fs.readFileSync(filePath, 'utf8');
  return parseCsvContent(raw);
}

function normalizeVark(value) {
  const raw = safeString(value, 'ReadWrite').toLowerCase();
  if (raw === 'visual') return 'visual';
  if (raw === 'aural' || raw === 'auditory') return 'aural';
  if (raw === 'kinesthetic') return 'kinesthetic';
  return 'readwrite';
}

function normalizeLevel(value) {
  const raw = safeString(value, 'Foundation').toLowerCase();
  if (raw === 'build') return 'build';
  if (raw === 'compete') return 'compete';
  if (raw === 'maintain') return 'maintain';
  return 'foundation';
}

function normalizeLength(value) {
  const raw = safeString(value, 'standard').toLowerCase();
  if (raw.startsWith('micro')) return 'micro';
  if (raw.startsWith('deep')) return 'deep';
  return 'standard';
}

function validateContentLibraryIntegrity(entries, options = {}) {
  const templateIds = Array.isArray(options.templateIds)
    ? options.templateIds.filter(Boolean)
    : [];
  const expectedRows =
    typeof options.expectedRows === 'number' && options.expectedRows > 0
      ? options.expectedRows
      : templateIds.length *
        EXPECTED_VARK_MODES.length *
        EXPECTED_LEVELS.length *
        EXPECTED_LENGTHS.length;

  const matrixCount = new Map();
  const unknownTemplateRows = [];

  for (const entry of entries || []) {
    const templateId = safeString(entry.template_id || entry.templateId);
    if (!templateId) {
      continue;
    }

    if (templateIds.length && !templateIds.includes(templateId)) {
      unknownTemplateRows.push(templateId);
      continue;
    }

    const vark = normalizeVark(entry.vark_mode || entry.varkMode);
    const level = normalizeLevel(entry.level);
    const length = normalizeLength(entry.length);
    const key = `${templateId}|${vark}|${level}|${length}`;
    matrixCount.set(key, (matrixCount.get(key) || 0) + 1);
  }

  const missingCombinations = [];
  for (const templateId of templateIds) {
    for (const vark of EXPECTED_VARK_MODES) {
      for (const level of EXPECTED_LEVELS) {
        for (const length of EXPECTED_LENGTHS) {
          const key = `${templateId}|${vark}|${level}|${length}`;
          if (!matrixCount.has(key)) {
            missingCombinations.push(key);
          }
        }
      }
    }
  }

  const duplicateCombinations = Array.from(matrixCount.entries())
    .filter(([, count]) => count > 1)
    .map(([key, count]) => ({ key, count }));

  const observedRows = Array.isArray(entries) ? entries.length : 0;
  const errors = [];

  if (observedRows < expectedRows) {
    errors.push(`content_rows_too_low:${observedRows}<${expectedRows}`);
  }
  if (missingCombinations.length > 0) {
    errors.push(`missing_matrix_slots:${missingCombinations.length}`);
  }
  if (duplicateCombinations.length > 0) {
    errors.push(`duplicate_matrix_slots:${duplicateCombinations.length}`);
  }
  if (unknownTemplateRows.length > 0) {
    errors.push(`unknown_templates:${unknownTemplateRows.length}`);
  }

  return {
    ok: errors.length === 0,
    errors,
    expectedRows,
    observedRows,
    matrixSlotsExpected:
      templateIds.length *
      EXPECTED_VARK_MODES.length *
      EXPECTED_LEVELS.length *
      EXPECTED_LENGTHS.length,
    matrixSlotsPresent: matrixCount.size,
    missingCombinations,
    duplicateCombinations,
    unknownTemplateRows,
  };
}

module.exports = {
  EXPECTED_VARK_MODES,
  EXPECTED_LEVELS,
  EXPECTED_LENGTHS,
  parseCsvContent,
  parseCsvFile,
  validateContentLibraryIntegrity,
  normalizeVark,
  normalizeLevel,
  normalizeLength,
};
