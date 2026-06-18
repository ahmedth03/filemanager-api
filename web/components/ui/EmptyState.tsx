export default function EmptyState({ title, description, icon }: { title: string; description?: string; icon?: string }) {
  return (
    <div className="text-center py-16">
      <div className="text-5xl mb-4">{icon ?? '🔍'}</div>
      <h3 className="text-lg font-semibold text-gray-700">{title}</h3>
      {description && <p className="text-gray-400 text-sm mt-1">{description}</p>}
    </div>
  )
}
