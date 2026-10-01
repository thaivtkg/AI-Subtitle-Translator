from dataclasses import dataclass


@dataclass(frozen=True)
class GlossaryEntry:
    source_term: str
    preferred_translation: str
    forbidden_alternatives: tuple[str, ...] = ()

    def __post_init__(self):
        _validate_text(self.source_term, "source_term")
        _validate_text(self.preferred_translation, "preferred_translation")
        if not isinstance(self.forbidden_alternatives, (list, tuple)):
            raise ValueError("forbidden_alternatives must be a sequence")

        values = []
        for value in self.forbidden_alternatives:
            _validate_text(value, "forbidden_alternative")
            if value not in values:
                values.append(value)
        object.__setattr__(self, "forbidden_alternatives", tuple(values))


@dataclass(frozen=True)
class GlossaryHit:
    source_term: str
    preferred_translation: str
    start: int
    end: int


class Glossary:
    def __init__(self, entries=()):
        self._entries = {}
        self.add_entries(entries)

    @classmethod
    def from_entries(cls, entries):
        return cls(entries)

    @classmethod
    def from_payload(cls, payload):
        if not isinstance(payload, dict):
            raise ValueError("glossary must be an object")

        entries = []
        for source_term, value in payload.items():
            if not isinstance(value, dict):
                raise ValueError("glossary entry must be an object")
            if "preferred_translation" not in value:
                raise ValueError("missing preferred_translation")
            if "forbidden_alternatives" not in value:
                raise ValueError("missing forbidden_alternatives")
            entries.append(
                GlossaryEntry(
                    source_term,
                    value["preferred_translation"],
                    value["forbidden_alternatives"],
                )
            )
        return cls(entries)

    def add(self, source_term, preferred_translation, forbidden_alternatives=()):
        self.add_entries(
            [(source_term, preferred_translation, forbidden_alternatives)]
        )

    def add_entries(self, entries):
        candidate = dict(self._entries)
        for raw_entry in entries:
            entry = _coerce_entry(raw_entry)
            existing = candidate.get(entry.source_term)
            if existing is None:
                candidate[entry.source_term] = entry
                continue
            if (
                existing.preferred_translation != entry.preferred_translation
                or set(existing.forbidden_alternatives)
                != set(entry.forbidden_alternatives)
            ):
                raise ValueError(
                    f"Conflicting glossary entry: {entry.source_term!r}"
                )
        self._entries = candidate

    def update(self, source_term, preferred_translation, forbidden_alternatives=()):
        if source_term not in self._entries:
            raise KeyError(source_term)
        entry = GlossaryEntry(
            source_term, preferred_translation, forbidden_alternatives
        )
        candidate = dict(self._entries)
        candidate[source_term] = entry
        self._entries = candidate

    def remove(self, source_term):
        candidate = dict(self._entries)
        del candidate[source_term]
        self._entries = candidate

    def replace_source_term(
        self, old_source_term, new_source_term, preferred_translation, forbidden_alternatives=()
    ):
        if old_source_term not in self._entries:
            raise KeyError(old_source_term)
        replacement = GlossaryEntry(
            new_source_term, preferred_translation, forbidden_alternatives
        )
        candidate = dict(self._entries)
        del candidate[old_source_term]
        existing = candidate.get(new_source_term)
        if existing is not None and existing != replacement:
            raise ValueError(f"Conflicting glossary entry: {new_source_term!r}")
        candidate[new_source_term] = replacement
        self._entries = candidate

    def get(self, source_term, default=None):
        return self._entries.get(source_term, default)

    def to_payload(self):
        return {
            source_term: {
                "preferred_translation": entry.preferred_translation,
                "forbidden_alternatives": list(entry.forbidden_alternatives),
            }
            for source_term, entry in self._entries.items()
        }

    def match(self, source_text):
        if not isinstance(source_text, str):
            raise ValueError("source_text must be a string")

        candidates = []
        for entry in self._entries.values():
            start = source_text.find(entry.source_term)
            while start >= 0:
                candidates.append(
                    GlossaryHit(
                        entry.source_term,
                        entry.preferred_translation,
                        start,
                        start + len(entry.source_term),
                    )
                )
                start = source_text.find(entry.source_term, start + 1)

        candidates.sort(key=lambda hit: (-len(hit.source_term), hit.start))
        selected = []
        for candidate in candidates:
            if not any(_overlaps(candidate, hit) for hit in selected):
                selected.append(candidate)
        return tuple(sorted(selected, key=lambda hit: hit.start))

    def __len__(self):
        return len(self._entries)


def _coerce_entry(raw_entry):
    if isinstance(raw_entry, GlossaryEntry):
        return raw_entry
    try:
        source_term, preferred_translation, forbidden_alternatives = raw_entry
    except (TypeError, ValueError) as error:
        raise ValueError("glossary entry must have three values") from error
    return GlossaryEntry(
        source_term, preferred_translation, forbidden_alternatives
    )


def _validate_text(value, field_name):
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{field_name} must not be empty")


def _overlaps(left, right):
    return left.start < right.end and right.start < left.end
