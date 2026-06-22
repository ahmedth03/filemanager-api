import AdminHeader from '@/components/admin/AdminHeader';
import CarForm from '@/components/admin/CarForm';

export default function NewCarPage() {
  return (
    <div>
      <AdminHeader title="Ajouter un véhicule" />
      <div className="p-6 max-w-4xl">
        <CarForm />
      </div>
    </div>
  );
}
