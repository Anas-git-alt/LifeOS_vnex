type StatusPillProps = {
  label: string;
  tone?: "green" | "amber" | "red" | "blue" | "neutral";
};

export function StatusPill({ label, tone = "neutral" }: StatusPillProps) {
  return <span className={`status-pill status-pill--${tone}`}>{label}</span>;
}
