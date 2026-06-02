insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', false, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('certificates', 'certificates', false, 10485760, array['application/pdf']),
  ('reports', 'reports', false, 10485760, array['application/pdf', 'text/csv', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']),
  ('organization-assets', 'organization-assets', false, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create or replace function public.safe_uuid(value text)
returns uuid
language plpgsql
immutable
as $$
begin
  return value::uuid;
exception
  when others then
    return null;
end;
$$;

drop policy if exists "avatar_owner_read" on storage.objects;
create policy "avatar_owner_read"
on storage.objects for select
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "avatar_owner_write" on storage.objects;
create policy "avatar_owner_write"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "avatar_owner_update" on storage.objects;
create policy "avatar_owner_update"
on storage.objects for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "staff_read_private_documents" on storage.objects;
create policy "staff_read_private_documents"
on storage.objects for select
to authenticated
using (
  bucket_id in ('certificates', 'reports', 'organization-assets')
  and public.has_org_role(public.safe_uuid((storage.foldername(name))[1]), array['admin','supervisor','teacher']::public.user_role[])
);

drop policy if exists "staff_write_private_documents" on storage.objects;
create policy "staff_write_private_documents"
on storage.objects for insert
to authenticated
with check (
  bucket_id in ('certificates', 'reports', 'organization-assets')
  and public.has_org_role(public.safe_uuid((storage.foldername(name))[1]), array['admin','supervisor']::public.user_role[])
);
