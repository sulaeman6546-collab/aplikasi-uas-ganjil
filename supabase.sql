-- Jalankan seluruh SQL ini di Supabase > SQL Editor.
create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text not null default '',
 role text not null check (role in ('teacher','student')),
 student_number text default '',
 class_name text default '',
 created_at timestamptz default now()
);
create table if not exists public.exams (
 id uuid primary key default gen_random_uuid(),
 teacher_id uuid not null references public.profiles(id),
 school_name text default '',
 title text not null,
 subject text not null default '',
 class_name text not null default '',
 semester text not null default 'Ganjil',
 academic_year text not null default '2026/2027',
 duration_minutes int not null default 90,
 instructions text default '',
 status text not null default 'draft' check(status in ('draft','published','closed')),
 start_at timestamptz,
 end_at timestamptz,
 created_at timestamptz default now()
);
create table if not exists public.questions (
 id uuid primary key default gen_random_uuid(),
 exam_id uuid not null references public.exams(id) on delete cascade,
 sort_order int not null default 1,
 question_type text not null check(question_type in ('mcq','essay')),
 question_html text not null,
 options jsonb not null default '[]'::jsonb,
 correct_answer text,
 points numeric not null default 1
);
create table if not exists public.attempts (
 id uuid primary key default gen_random_uuid(),
 exam_id uuid not null references public.exams(id) on delete cascade,
 student_id uuid not null references public.profiles(id),
 started_at timestamptz default now(),
 submitted_at timestamptz,
 score numeric,
 essay_pending boolean default true,
 unique(exam_id,student_id)
);
create table if not exists public.answers (
 id uuid primary key default gen_random_uuid(),
 attempt_id uuid not null references public.attempts(id) on delete cascade,
 question_id uuid not null references public.questions(id) on delete cascade,
 answer_text text default '',
 is_correct boolean,
 earned_points numeric default 0,
 updated_at timestamptz default now(),
 unique(attempt_id,question_id)
);
alter table public.profiles enable row level security;
alter table public.exams enable row level security;
alter table public.questions enable row level security;
alter table public.attempts enable row level security;
alter table public.answers enable row level security;

-- Profil: pengguna dapat melihat/mengubah profilnya sendiri.
create policy "profile self read" on public.profiles for select using(id=auth.uid());
create policy "profile self insert" on public.profiles for insert with check(id=auth.uid());
create policy "profile self update" on public.profiles for update using(id=auth.uid()) with check(id=auth.uid());

-- Ujian: guru mengelola miliknya; siswa melihat ujian terbit.
create policy "teacher manages own exams" on public.exams for all using(teacher_id=auth.uid()) with check(teacher_id=auth.uid());
create policy "students read published exams" on public.exams for select using(status='published');

-- Soal dikelola guru pemilik ujian; siswa hanya membaca soal ujian terbit.
create policy "teacher manages questions" on public.questions for all
 using(exists(select 1 from public.exams e where e.id=exam_id and e.teacher_id=auth.uid()))
 with check(exists(select 1 from public.exams e where e.id=exam_id and e.teacher_id=auth.uid()));
create policy "students read published questions" on public.questions for select
 using(exists(select 1 from public.exams e where e.id=exam_id and e.status='published'));

-- Attempt siswa sendiri; guru dapat melihat attempt ujian miliknya.
create policy "student reads own attempts" on public.attempts for select using(student_id=auth.uid());
create policy "student creates own attempts" on public.attempts for insert with check(student_id=auth.uid());
create policy "student updates own attempts" on public.attempts for update using(student_id=auth.uid()) with check(student_id=auth.uid());
create policy "teacher reads exam attempts" on public.attempts for select
 using(exists(select 1 from public.exams e where e.id=exam_id and e.teacher_id=auth.uid()));

create policy "student reads own answers" on public.answers for select
 using(exists(select 1 from public.attempts a where a.id=attempt_id and a.student_id=auth.uid()));
create policy "student writes own answers" on public.answers for all
 using(exists(select 1 from public.attempts a where a.id=attempt_id and a.student_id=auth.uid() and a.submitted_at is null))
 with check(exists(select 1 from public.attempts a where a.id=attempt_id and a.student_id=auth.uid() and a.submitted_at is null));
create policy "teacher reads answers" on public.answers for select
 using(exists(select 1 from public.attempts a join public.exams e on e.id=a.exam_id where a.id=attempt_id and e.teacher_id=auth.uid()));

-- Bucket gambar soal. File dapat dibaca siswa, unggah dibatasi user terautentikasi.
insert into storage.buckets(id,name,public) values('question-images','question-images',true) on conflict(id) do nothing;
create policy "question image public read" on storage.objects for select using(bucket_id='question-images');
create policy "authenticated upload question images" on storage.objects for insert to authenticated with check(bucket_id='question-images');
create policy "owner delete question images" on storage.objects for delete to authenticated using(bucket_id='question-images' and owner=auth.uid());

-- Catatan: role dipilih saat pendaftaran untuk demo awal. Untuk penggunaan resmi,
-- batasi pembuatan akun guru melalui undangan/admin dan jangan biarkan siswa memilih teacher.
