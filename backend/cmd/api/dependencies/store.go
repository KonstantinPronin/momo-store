package dependencies

import (
	"gitlab.praktikum-services.ru/Stasyan/momo-store/internal/store/dumplings"
	"gitlab.praktikum-services.ru/Stasyan/momo-store/internal/store/dumplings/fake"
)

// NewFakeDumplingsStore returns new fake store for app
func NewFakeDumplingsStore() (dumplings.Store, error) {
	packs := []dumplings.Product{
		{
			ID:          1,
			Name:        "Пельмени",
			Description: "С говядиной",
			Price:       5.00,
			Image:       "https://storage.yandexcloud.net/momo-store-std-011-009/momo-img-1",
		},
		{
			ID:          2,
			Name:        "Хинкали",
			Description: "Со свининой",
			Price:       3.50,
			Image:       "https://storage.yandexcloud.net/momo-store-std-011-009/momo-img-2",
		},
		{
			ID:          3,
			Name:        "Манты",
			Description: "С мясом молодых бычков",
			Price:       2.75,
			Image:       "https://storage.yandexcloud.net/momo-store-std-011-009/momo-img-3",
		},
		{
			ID:          4,
			Name:        "Буузы",
			Description: "С телятиной и луком",
			Price:       4.00,
			Image:       "https://storage.yandexcloud.net/momo-store-std-011-009/momo-img-4",
		},
		{
			ID:          5,
			Name:        "Цзяоцзы",
			Description: "С говядиной и свининой",
			Price:       7.25,
			Image:       "https://storage.yandexcloud.net/momo-store-std-011-009/momo-img-5",
		},
		{
			ID:          6,
			Name:        "Гедза",
			Description: "С соевым мясом",
			Price:       3.50,
			Image:       "https://storage.yandexcloud.net/momo-store-std-011-009/momo-img-6",
		},
		{
			ID:          7,
			Name:        "Дим-самы",
			Description: "С уткой",
			Price:       2.65,
			Image:       "https://storage.yandexcloud.net/momo-store-std-011-009/momo-img-7",
		},
		{
			ID:          8,
			Name:        "Момо",
			Description: "С бараниной",
			Price:       5.00,
			Image:       "https://storage.yandexcloud.net/momo-store-std-011-009/momo-img-8",
		},
		{
			ID:          9,
			Name:        "Вонтоны",
			Description: "С креветками",
			Price:       4.10,
			Image:       "https://storage.yandexcloud.net/momo-store-std-011-009/momo-img-1",
		},
		{
			ID:          10,
			Name:        "Баоцзы",
			Description: "С капустой",
			Price:       4.20,
			Image:       "https://storage.yandexcloud.net/momo-store-std-011-009/momo-img-2",
		},
		{
			ID:          11,
			Name:        "Кундюмы",
			Description: "С грибами",
			Price:       5.45,
			Image:       "https://storage.yandexcloud.net/momo-store-std-011-009/momo-img-3",
		},
		{
			ID:          12,
			Name:        "Курзе",
			Description: "С крабом",
			Price:       3.25,
			Image:       "https://storage.yandexcloud.net/momo-store-std-011-009/momo-img-4",
		},
		{
			ID:          13,
			Name:        "Бораки",
			Description: "С говядиной и бараниной",
			Price:       4.00,
			Image:       "https://storage.yandexcloud.net/momo-store-std-011-009/momo-img-5",
		},
		{
			ID:          14,
			Name:        "Равиоли",
			Description: "С рикоттой",
			Price:       2.90,
			Image:       "https://storage.yandexcloud.net/momo-store-std-011-009/momo-img-6",
		},
	}

	store := fake.NewStore()
	store.SetAvailablePacks(packs...)

	return store, nil
}
