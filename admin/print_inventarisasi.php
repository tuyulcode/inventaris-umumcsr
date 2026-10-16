<?php
session_start();
include '../config/database.php';

if (!isset($_SESSION['user_id']) || $_SESSION['level'] !== 'admin') {
    header('Location: ../index.php');
    exit;
}

$page_title = 'Print Data Inventarisasi';
$active_menu = 'print_inventarisasi';

// ===== FILTER =====
$unit_id  = isset($_GET['unit_id']) ? intval($_GET['unit_id']) : 0;
$ruang_id = isset($_GET['ruang_id']) ? intval($_GET['ruang_id']) : 0;
$kondisi  = isset($_GET['kondisi']) ? trim($_GET['kondisi']) : '';

$where_clauses = ["b.status_aktif = 'aktif'"];
if ($unit_id > 0) {
    $where_clauses[] = "b.id_unit = " . intval($unit_id);
}
if ($ruang_id > 0) {
    $where_clauses[] = "b.id_ruang = " . intval($ruang_id);
}
if ($kondisi !== '') {
    $where_clauses[] = "b.kondisi = '" . $conn->real_escape_string($kondisi) . "'";
}
$where_sql = " WHERE " . implode(' AND ', $where_clauses);

// Selected labels for report title
$selected_unit_name = 'SEMUA UNIT';
if ($unit_id > 0) {
    $stmt = $conn->prepare("SELECT nama_unit FROM unit WHERE id = ?");
    $stmt->bind_param("i", $unit_id);
    $stmt->execute();
    if ($r = $stmt->get_result()->fetch_assoc()) {
        $selected_unit_name = strtoupper($r['nama_unit']);
    }
    $stmt->close();
}

$selected_ruang_name = 'SEMUA RUANG';
if ($ruang_id > 0) {
    $stmt = $conn->prepare("SELECT nama_ruang FROM ruang WHERE id = ?");
    $stmt->bind_param("i", $ruang_id);
    $stmt->execute();
    if ($r = $stmt->get_result()->fetch_assoc()) {
        $selected_ruang_name = strtoupper($r['nama_ruang']);
    }
    $stmt->close();
}

$selected_kondisi_name = $kondisi !== '' ? strtoupper($kondisi) : 'SEMUA KONDISI';

$report_title = 'DATA INVENTARISASI';
$report_subtitle = 'UNIT "' . $selected_unit_name . '" - RUANG "' . $selected_ruang_name . '" - KONDISI "' . $selected_kondisi_name . '"';

// ===== DATA =====
$query = "SELECT b.id, b.nama_barang, b.jumlah, b.kondisi, b.tgl_pembelian,
                 m.nama_merk, j.nama_jenis, k.nama_kategori,
                 u.nama_unit, r.nama_ruang
          FROM barang b
          LEFT JOIN merk m ON b.id_merk = m.id
          LEFT JOIN jenis j ON b.id_jenis = j.id
          LEFT JOIN kategori k ON b.id_kategori = k.id
          LEFT JOIN unit u ON b.id_unit = u.id
          LEFT JOIN ruang r ON b.id_ruang = r.id
          $where_sql
          ORDER BY u.nama_unit ASC, r.nama_ruang ASC, b.nama_barang ASC, b.id ASC";
$data = $conn->query($query);

// Dropdowns
$units = [];
$un_res = $conn->query("SELECT id, nama_unit FROM unit ORDER BY nama_unit ASC");
if ($un_res) {
    while ($r = $un_res->fetch_assoc()) $units[] = $r;
}

$rooms = [];
if ($unit_id > 0) {
    $ru_res = $conn->query("SELECT id, nama_ruang FROM ruang WHERE id_unit = " . intval($unit_id) . " ORDER BY nama_ruang ASC");
    if ($ru_res) {
        while ($r = $ru_res->fetch_assoc()) $rooms[] = $r;
    }
}

include '../includes/header.php';
include '../includes/sidebar.php';
?>

<!-- Content Header -->
<div class="content-header">
    <div class="container-fluid">
        <div class="row mb-2">
            <div class="col-sm-6">
                <h1>Print Data Inventarisasi</h1>
            </div>
            <div class="col-sm-6">
                <ol class="breadcrumb float-sm-right">
                    <li class="breadcrumb-item"><a href="index.php">Dashboard</a></li>
                    <li class="breadcrumb-item">Master Data</li>
                    <li class="breadcrumb-item active">Print Data Inventarisasi</li>
                </ol>
            </div>
        </div>
    </div>
</div>

<section class="content">
    <div class="container-fluid">
        <!-- Filter Card -->
        <div class="card mb-3">
            <div class="card-header">
                <h3 class="card-title"><i class="fas fa-filter mr-2" style="color:#6366f1;"></i>Filter Data</h3>
            </div>
            <div class="card-body">
                <form method="GET" action="print_inventarisasi.php" class="row align-items-end">
                    <div class="col-md-4">
                        <div class="form-group mb-2">
                            <label style="font-size: 12px; font-weight: 700;">Unit</label>
                            <select name="unit_id" id="filter_unit" class="form-control form-control-sm select2">
                                <option value="">-- Semua Unit --</option>
                                <?php foreach ($units as $u): ?>
                                    <option value="<?= $u['id'] ?>" <?= $unit_id == $u['id'] ? 'selected' : '' ?>>
                                        <?= htmlspecialchars($u['nama_unit']) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="form-group mb-2">
                            <label style="font-size: 12px; font-weight: 700;">Ruang</label>
                            <select name="ruang_id" id="filter_ruang" class="form-control form-control-sm select2">
                                <option value="">-- Semua Ruang --</option>
                                <?php foreach ($rooms as $r): ?>
                                    <option value="<?= $r['id'] ?>" <?= $ruang_id == $r['id'] ? 'selected' : '' ?>>
                                        <?= htmlspecialchars($r['nama_ruang']) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                    </div>
                    <div class="col-md-2">
                        <div class="form-group mb-2">
                            <label style="font-size: 12px; font-weight: 700;">Kondisi</label>
                            <select name="kondisi" class="form-control form-control-sm select2">
                                <option value="">-- Semua Kondisi --</option>
                                <?php foreach (['Baik', 'Rusak', 'Hilang'] as $k): ?>
                                    <option value="<?= $k ?>" <?= $kondisi === $k ? 'selected' : '' ?>><?= $k ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                    </div>
                    <div class="col-md-2">
                        <div class="form-group mb-2">
                            <button type="submit" class="btn btn-primary btn-sm">
                                <i class="fas fa-filter mr-1"></i> Tampilkan
                            </button>
                            <a href="print_inventarisasi.php" class="btn btn-secondary btn-sm">
                                <i class="fas fa-sync-alt"></i>
                            </a>
                        </div>
                    </div>
                </form>
            </div>
        </div>

        <div class="card">
            <div class="card-header">
                <h3 class="card-title"><i class="fas fa-file-pdf mr-2" style="color:#6366f1;"></i>Data Inventarisasi</h3>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table id="dataTableLaporan" class="table table-hover table-striped table-bordered">
                        <thead>
                            <tr class="bg-light">
                                <th width="45" class="text-center">No</th>
                                <th width="80" class="text-center">ID Barang</th>
                                <th>Nama Barang</th>
                                <th>Merk</th>
                                <th>Jenis</th>
                                <th>Kategori</th>
                                <th>Unit</th>
                                <th>Ruang</th>
                                <th width="70" class="text-center">Jumlah</th>
                                <th width="90" class="text-center">Kondisi</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php $no = 1; while ($row = $data->fetch_assoc()): ?>
                            <tr>
                                <td class="text-center"><?= $no++ ?></td>
                                <td class="text-center"><code><?= str_pad($row['id'], 5, '0', STR_PAD_LEFT) ?></code></td>
                                <td><strong><?= htmlspecialchars($row['nama_barang']) ?></strong></td>
                                <td><?= htmlspecialchars($row['nama_merk'] ?? '-') ?></td>
                                <td><?= htmlspecialchars($row['nama_jenis'] ?? '-') ?></td>
                                <td><?= htmlspecialchars($row['nama_kategori'] ?? '-') ?></td>
                                <td><?= htmlspecialchars($row['nama_unit'] ?? '-') ?></td>
                                <td><?= htmlspecialchars($row['nama_ruang'] ?? '-') ?></td>
                                <td class="text-center"><strong><?= intval($row['jumlah']) ?></strong></td>
                                <td class="text-center">
                                    <?php
                                    $badge = 'success';
                                    if ($row['kondisi'] == 'Rusak') $badge = 'warning';
                                    if ($row['kondisi'] == 'Hilang') $badge = 'danger';
                                    ?>
                                    <span class="badge badge-<?= $badge ?>"><?= htmlspecialchars($row['kondisi']) ?></span>
                                </td>
                            </tr>
                            <?php endwhile; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</section>

<script>
$(function () {
    let reportTitle = '<?= addslashes($report_title) ?>';
    let reportSubtitle = '<?= addslashes($report_subtitle) ?>';

    var table = $("#dataTableLaporan").DataTable({
        "responsive": true,
        "lengthChange": false,
        "autoWidth": false,
        "ordering": true,
        "order": [[1, 'asc']],
        "buttons": [
            {
                extend: 'pdfHtml5',
                text: '<i class="fas fa-file-pdf mr-1"></i> Generate PDF',
                className: 'btn-danger btn-sm',
                title: reportTitle,
                messageTop: reportSubtitle,
                orientation: 'landscape',
                pageSize: 'A4',
                exportOptions: { columns: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] },
                customize: function (doc) {
                    doc.styles.title = { fontSize: 14, bold: true, alignment: 'center' };
                    doc.styles.tableHeader = { fontSize: 8, bold: true, alignment: 'center', fillColor: '#e5e7eb' };
                    doc.defaultStyle.fontSize = 8;
                    if (doc.content[1]) doc.content[1].margin = [0, 0, 0, 10];
                }
            },
            {
                extend: 'excelHtml5',
                text: '<i class="fas fa-file-excel mr-1"></i> Excel',
                className: 'btn-success btn-sm',
                title: reportTitle,
                messageTop: reportSubtitle,
                exportOptions: { columns: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] }
            },
            {
                extend: 'print',
                text: '<i class="fas fa-print mr-1"></i> Print',
                className: 'btn-info btn-sm',
                title: reportTitle,
                messageTop: '<h4>' + reportSubtitle + '</h4>',
                exportOptions: { columns: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] }
            }
        ]
    });

    table.buttons().container().appendTo('#dataTableLaporan_wrapper .col-md-6:eq(0)');

    // Dependent Dropdown: Unit -> Ruang
    $('#filter_unit').change(function () {
        let unitId = $(this).val();
        let target = $('#filter_ruang');

        target.html('<option value="">-- Memuat... --</option>').trigger('change');

        if (unitId) {
            $.getJSON('get_ruang.php', { unit_id: unitId }, function (data) {
                let options = '<option value="">-- Semua Ruang --</option>';
                data.forEach(function (r) {
                    options += `<option value="${r.id}">${r.nama_ruang}</option>`;
                });
                target.html(options).trigger('change');
            });
        } else {
            target.html('<option value="">-- Semua Ruang --</option>').trigger('change');
        }
    });
});
</script>

<?php include '../includes/footer.php'; ?>
